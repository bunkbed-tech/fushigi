FROM oven/bun:1.1

WORKDIR /app

COPY package.json bun.lock ./

RUN bun install

COPY src ./src
COPY static ./static
COPY vite.config.ts tsconfig.json svelte.config.js components.json ./

RUN rm -rf node_modules/.bun && bun install

CMD ["bun","--bun", "run", "dev", "--host", "0.0.0.0"]
