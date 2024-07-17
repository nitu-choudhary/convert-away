# Build stage
FROM node:18 AS build 

WORKDIR /app

# Copy package.json and package-lock.json
COPY package.json yarn.lock ./

# Install Rollup to take care of errors during build process
RUN yarn add --save-dev rollup @rollup/plugin-node-resolve @rollup/plugin-commonjs

# Install dependencies
RUN yarn install

# Copy the rest of the application code
COPY . .

# Build the React application
RUN yarn build

# Production stage
FROM nginx:alpine 

WORKDIR /usr/share/nginx/html

# Remove default nginx static assets
RUN rm -rf ./*

# Copy dist folder from the build image
COPY --from=build /app/dist /usr/share/nginx/html

# Expose the listening port 
EXPOSE 80

# Start Nginx server to serve your react application
CMD ["nginx", "-g", "daemon off;"]