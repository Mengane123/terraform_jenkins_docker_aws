#node.js application container 
FROM node:18-alpine 

WORKDIR /app 

#copying all package files 
COPY package*.json ./


#installing all dependencies 
RUN npm install --production 


#copying application code 
COPY server.js . 
COPY public ./public 

#exposing port 3000 
EXPOSE 3000 


# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health', (r) => {if (r.statusCode !== 200) throw new Error(r.statusCode)})"


#starting application 
CMD ["node", "server.js"]
