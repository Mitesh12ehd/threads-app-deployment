// Resource: https://clerk.com/docs/nextjs/middleware#auth-middleware
// Copy the middleware code as it is from the above resource

import { authMiddleware } from "@clerk/nextjs";
import { NextRequest, NextResponse } from 'next/server';
import { httpRequestsTotal, httpRequestDuration } from '@/lib/metrics';

export async function middleware(req: NextRequest) {
  if (req.nextUrl.pathname === "/api/metrics") {
    return NextResponse.next();
  }

  const start = Date.now();
  const res = NextResponse.next();
  
  const duration = (Date.now() - start) / 1000;
  const route = req.nextUrl.pathname;
  const status = res.status.toString();
  
  httpRequestsTotal.inc({ method: req.method, route, status });
  httpRequestDuration.observe({ method: req.method, route, status }, duration);
  
  return res;
}

export default authMiddleware({
  // An array of public routes that don't require authentication.
  publicRoutes: ["/api/webhook/clerk"],

  // An array of routes to be ignored by the authentication middleware.
  ignoredRoutes: ["/api/webhook/clerk"],
});

export const config = {
  matcher: ["/((?!.*\\..*|_next).*)", "/", "/(api|trpc)(.*)"],
};
