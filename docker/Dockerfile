# Stage-1 : Install dependencies
FROM node:20-alpine AS deps
WORKDIR /app
COPY application/package*.json ./

# npm ci install what exactly specified in package-lock.json
RUN npm prune --omit=dev



# Stage-2 : Build application
FROM node:20-alpine AS builder
WORKDIR /app

# copy dependency from stage-1
COPY --from=deps /app/node_modules ./node_modules

# copy source code
COPY application/ .

# build ( to generate .next/standalone)
RUN npm run build




# Stage-3: Run application
FROM node:20-alpine AS runner
WORKDIR /app

COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static
COPY --from=builder /app/public ./public

EXPOSE 3000
ENV NODE_ENV=production
CMD ["node","server.js"]