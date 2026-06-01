import { registry } from '@/lib/metrics';
import { NextResponse } from 'next/server';

export async function GET() {
  const metrics = await registry.metrics();
  return new NextResponse(metrics, {
    headers: { 'Content-Type': registry.contentType },
  });
}