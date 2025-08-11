# Stage 1 - Build stage - Simply copy-pasting files and compiling the sources
FROM node:22-alpine AS build

WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY tsconfig.json ./
COPY src ./src

RUN npm run build

# Stage 2 - Run stage - A more complicated one
FROM node:22-alpine AS runtime

WORKDIR /app

# Creating non-root user for security 
RUN addgroup -S testinggroup && adduser -S kek -G testinggroup

# Installing deps only from "dependencies" block of package.json
# Omitting the "devDependencies" one
COPY --from=build /app/package*.json ./
RUN npm ci --omit=dev

# Copying our built artifact from the build stage
COPY --from=build /app/dist ./dist

# Making our 'kek' user an owner of /app folder
RUN chown -R kek:testinggroup /app


# Using tini as an entrypoint to properly handle SIGTERM and reap zombie processes
ENV TINI_VERSION=v0.19.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini

# Switching to the our user for runtime
USER kek

ENTRYPOINT ["/tini", "--"]

# Running our backend app 
CMD ["npm", "run", "start:prod"]