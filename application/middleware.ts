import { authMiddleware } from "@clerk/nextjs";
import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";
import { httpRequestCount, httpRequestDuration } from "@/lib/metrics";

export default authMiddleware({
  publicRoutes: ["/api/webhook/clerk", "/api/metrics"],
  ignoredRoutes: ["/api/webhook/clerk"],

  afterAuth(auth, req: NextRequest) {
    const start = Date.now();
    const method = req.method;
    const route = req.nextUrl.pathname;

    const response = NextResponse.next();

    // Hook into the response to record metrics
    const status = response.status.toString();
    const duration = (Date.now() - start) / 1000;

    httpRequestCount.inc({ method, route, status });
    httpRequestDuration.observe({ method, route, status }, duration);

    return response;
  },
});

export const config = {
  matcher: ["/((?!.*\\..*|_next).*)", "/", "/(api|trpc)(.*)"],
};