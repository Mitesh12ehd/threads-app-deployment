import { authMiddleware } from "@clerk/nextjs";
import { NextRequest, NextResponse } from "next/server";

export default authMiddleware({
  // Public routes (NO AUTH)
  publicRoutes: [
    "/api/webhook/clerk",
    "/api/metrics", // ✅ IMPORTANT: allow Prometheus scraping
  ],

  // Routes ignored by Clerk entirely
  ignoredRoutes: [
    "/api/webhook/clerk",
    "/api/metrics", // ✅ prevents redirect/login interference
  ],
});

export const config = {
  matcher: [
    "/((?!.*\\..*|_next).*)",
    "/",
    "/(api|trpc)(.*)",
  ],
};