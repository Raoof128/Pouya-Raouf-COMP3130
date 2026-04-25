import { handleCors, jsonCorsHeaders } from "../_shared/cors.ts";

type Departure = {
  destination: string;
  line: string;
  minutesUntilDeparture: number;
  mode: string;
  platform: string;
  stopId: string;
};

type StopSearchResult = {
  id: string;
  name: string;
};

function getAllowedWebOrigins(): string[] {
  return (Deno.env.get("ALLOWED_WEB_ORIGINS") ?? "")
    .split(",")
    .map((origin) => origin.trim())
    .filter((origin) => origin.length > 0);
}

function getEnvOrThrow(name: string): string {
  const value = Deno.env.get(name);
  if (!value) {
    throw new Error(`${name} is not configured`);
  }
  return value;
}

function toMinutes(iso: string): number {
  const date = new Date(iso);
  const diffMs = date.getTime() - Date.now();
  const minutes = Math.floor(diffMs / 60000);
  return minutes < 0 ? 0 : minutes;
}

function modeToMotType(mode: string): string | null {
  return {
    bus: "5",
    metro: "2",
    train: "1",
  }[mode] ?? null;
}

function normalizeMode(
  value: string | null,
): "none" | "metro" | "bus" | "train" {
  if (value === "metro" || value === "bus" || value === "train") {
    return value;
  }
  return "none";
}

function inferMode(departure: Record<string, unknown>): string {
  const motType = String(
    ((departure.transportation as Record<string, unknown> | undefined)
      ?.product as Record<string, unknown> | undefined)?.class ??
      ((departure.transportation as Record<string, unknown> | undefined)
        ?.product as Record<string, unknown> | undefined)?.name ??
      "",
  ).toLowerCase();

  if (motType.includes("metro") || motType === "2") {
    return "metro";
  }
  if (motType.includes("train") || motType === "1") {
    return "train";
  }
  if (motType.includes("bus") || motType === "5") {
    return "bus";
  }
  return "unknown";
}

async function resolveNearestStopId({
  apiKey,
  latitude,
  longitude,
}: {
  apiKey: string;
  latitude: number;
  longitude: number;
}): Promise<string | null> {
  const nameSf = `${longitude}:${latitude}:EPSG:4326`;
  const params = new URLSearchParams({
    outputFormat: "rapidJSON",
    coordOutputFormat: "EPSG:4326",
    type_sf: "coord",
    name_sf: nameSf,
    version: "10.2.1.42",
  });
  const endpoint =
    `https://api.transport.nsw.gov.au/v1/tp/stop_finder?${params}`;
  const upstream = await fetch(endpoint, {
    headers: {
      Authorization: `apikey ${apiKey}`,
    },
    signal: AbortSignal.timeout(10000),
  });
  if (!upstream.ok) {
    return null;
  }
  const payload = await upstream.json() as {
    locations?: Array<{
      id?: string;
      disassembledName?: string;
      type?: string;
      parent?: { id?: string };
    }>;
  };
  const firstStop = (payload.locations ?? []).find((location) =>
    (location.type ?? "").toLowerCase().includes("stop") ||
    (location.type ?? "").toLowerCase().includes("platform")
  );
  return firstStop?.id ?? firstStop?.parent?.id ??
    firstStop?.disassembledName ?? null;
}

async function searchStops({
  apiKey,
  mode,
  query,
}: {
  apiKey: string;
  mode: "none" | "metro" | "bus" | "train";
  query: string;
}): Promise<StopSearchResult[]> {
  if (query.trim().length < 2) {
    return [];
  }

  const params = new URLSearchParams({
    coordOutputFormat: "EPSG:4326",
    name_sf: query.trim(),
    outputFormat: "rapidJSON",
    type_sf: "any",
    version: "10.2.1.42",
  });
  const endpoint =
    `https://api.transport.nsw.gov.au/v1/tp/stop_finder?${params}`;
  const upstream = await fetch(endpoint, {
    headers: {
      Authorization: `apikey ${apiKey}`,
    },
    signal: AbortSignal.timeout(10000),
  });
  if (!upstream.ok) {
    return [];
  }

  const payload = await upstream.json() as {
    locations?: Array<{
      disassembledName?: string;
      id?: string;
      name?: string;
      parent?: { id?: string };
      type?: string;
    }>;
  };

  const seenIds = new Set<string>();
  return (payload.locations ?? [])
    .filter((location) => {
      const type = (location.type ?? "").toLowerCase();
      return type.includes("stop") || type.includes("platform");
    })
    .map((location) => {
      const id = location.id ?? location.parent?.id ?? "";
      const name = location.disassembledName ?? location.name ?? id;
      return { id, name };
    })
    .filter((stop) => stop.id.length > 0 && stop.name.length > 0)
    .filter((stop) => stopMatchesMode(stop, mode))
    .filter((stop) => {
      if (seenIds.has(stop.id)) {
        return false;
      }
      seenIds.add(stop.id);
      return true;
    })
    .slice(0, 8);
}

function stopMatchesMode(
  stop: StopSearchResult,
  mode: "none" | "metro" | "bus" | "train",
): boolean {
  if (mode === "none") {
    return true;
  }

  const name = stop.name.toLowerCase();
  if (mode === "metro" || mode === "train") {
    return name.includes("station");
  }

  return (
    name.includes("stand") ||
    name.includes("interchange") ||
    name.includes("bus") ||
    !name.includes("station")
  );
}

Deno.serve(async (req) => {
  const allowedOrigins = getAllowedWebOrigins();
  const cors = handleCors(req, { allowedOrigins });
  if (cors) {
    return cors;
  }

  try {
    const apiKey = getEnvOrThrow("TFNSW_API_KEY");
    const url = new URL(req.url);
    if (url.searchParams.get("action") === "stop-search") {
      const stops = await searchStops({
        apiKey,
        mode: normalizeMode(url.searchParams.get("mode")),
        query: url.searchParams.get("q") ?? "",
      });
      return new Response(JSON.stringify(stops), {
        headers: {
          ...jsonCorsHeaders(req, { allowedOrigins }),
          "Content-Type": "application/json",
        },
      });
    }

    const commuteMode = normalizeMode(url.searchParams.get("mode"));
    const favoriteRoute = (url.searchParams.get("route") ?? "").trim()
      .toLowerCase();
    const preferredStopId = (url.searchParams.get("stopId") ?? "").trim();
    const latitude = Number(url.searchParams.get("lat"));
    const longitude = Number(url.searchParams.get("lng"));

    const stopIdFromLocation =
      Number.isFinite(latitude) && Number.isFinite(longitude)
        ? await resolveNearestStopId({ apiKey, latitude, longitude })
        : null;
    const stopId = preferredStopId.length > 0
      ? preferredStopId
      : stopIdFromLocation ?? Deno.env.get("TFNSW_STOP_ID") ?? "10101403";
    const params = new URLSearchParams({
      outputFormat: "rapidJSON",
      type_dm: "stop",
      name_dm: stopId,
      mode: "direct",
      depArrMacro: "dep",
      TfNSWDM: "true",
      version: "10.2.1.42",
    });
    const motType = modeToMotType(commuteMode);
    if (motType != null) {
      params.set("itdMot", motType);
    }
    const endpoint =
      `https://api.transport.nsw.gov.au/v1/tp/departure_mon?${params}`;

    const upstream = await fetch(endpoint, {
      headers: {
        Authorization: `apikey ${apiKey}`,
      },
      signal: AbortSignal.timeout(10000),
    });
    if (!upstream.ok) {
      return new Response(JSON.stringify([]), {
        headers: {
          ...jsonCorsHeaders(req, { allowedOrigins }),
          "Content-Type": "application/json",
        },
      });
    }

    const payload = await upstream.json() as {
      departures?: Array<Record<string, unknown>>;
    };

    const departures: Departure[] = (payload.departures ?? [])
      .map((item) => {
        const itemObj = item as {
          platform?: {
            name?: string;
            direction?: {
              name?: string;
              line?: {
                transportation?: {
                  number?: string;
                };
              };
            };
            stop?: {
              parent?: {
                departures?: string;
              };
            };
          };
          stop?: {
            parent?: {
              departures?: string;
            };
          };
          when?: string;
          transportation?: {
            product?: {
              class?: string;
              name?: string;
              number?: string;
            };
          };
        };
        const when = itemObj.when ??
          itemObj.stop?.parent?.departures ??
          itemObj.platform?.stop?.parent?.departures;
        const line =
          itemObj.platform?.direction?.line?.transportation?.number ??
            itemObj.transportation?.product?.number ??
            "";
        const destination = itemObj.platform?.direction?.name ?? "";
        const mode = inferMode(item as Record<string, unknown>);
        return {
          destination,
          line,
          mode,
          minutesUntilDeparture: when == null ? 0 : toMinutes(when),
          platform: itemObj.platform?.name ?? "",
          stopId,
        };
      })
      .filter((item) => item.destination.length > 0)
      .filter((item) =>
        commuteMode === "none" || item.mode === commuteMode ||
        item.mode === "unknown"
      )
      .filter((item) =>
        favoriteRoute.length === 0 ||
        item.destination.toLowerCase().includes(favoriteRoute) ||
        item.line.toLowerCase().includes(favoriteRoute)
      )
      .sort((a, b) => a.minutesUntilDeparture - b.minutesUntilDeparture)
      .slice(0, 3);

    return new Response(JSON.stringify(departures), {
      headers: {
        ...jsonCorsHeaders(req, { allowedOrigins }),
        "Content-Type": "application/json",
      },
    });
  } catch (_error) {
    return new Response(JSON.stringify([]), {
      headers: {
        ...jsonCorsHeaders(req, { allowedOrigins }),
        "Content-Type": "application/json",
      },
      status: 200,
    });
  }
});
