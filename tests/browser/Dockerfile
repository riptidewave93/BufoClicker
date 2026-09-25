FROM mcr.microsoft.com/playwright:v1.58.2-noble
WORKDIR /test
COPY package.json package-lock.json ./
RUN npm ci --ignore-scripts
ENV NODE_PATH=/test/node_modules
WORKDIR /app
CMD ["node", "tests/browser/check.cjs"]
