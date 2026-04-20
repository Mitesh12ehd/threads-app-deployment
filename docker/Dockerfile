FROM node:20-alpine

WORKDIR /app

# copy package.json
COPY application/package*.json ./

# Do npm install 
RUN npm install --legacy-peer-deps

# copy application code
COPY application/ .

# Build Next.js production bundle
RUN npm run build

# Port expose
EXPOSE 3000

# Run application
CMD ["npm","start"]