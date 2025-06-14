# Deployment Guide for Create Lamdera App - Darklang API

This guide explains how to deploy the Darklang API component of create-lamdera-app.

## 🚀 Quick Deployment

### 1. Create a Darklang Canvas

1. Go to [Darklang](https://darklang.com) and create a new account
2. Create a new canvas with a descriptive name like `create-lamdera-app`
3. Note your canvas URL (e.g., `https://your-canvas-name.dlio.live`)

### 2. Deploy the API Code

1. Copy the entire contents of `main.dark` 
2. Paste it into your Darklang canvas editor
3. The API will be automatically deployed and available

### 3. Test the Deployment

```bash
# Health check
curl https://your-canvas-name.dlio.live/health

# List templates
curl https://your-canvas-name.dlio.live/templates/list

# Test project creation
curl -X POST https://your-canvas-name.dlio.live/project/create \\
  -H "Content-Type: application/json" \\
  -d '{
    "config": {
      "name": "test-app",
      "useCursor": false,
      "createRepo": false,
      "repoVisibility": "private",
      "useTailwind": true,
      "useTest": false,
      "useI18n": false,
      "skipInstall": true,
      "packageManager": "npm"
    }
  }'
```

## 🔧 Configuration

### Environment Variables

Set these in your CLI environment:

```bash
export DARKLANG_API_URL=https://your-canvas-name.dlio.live
```

### Canvas Settings

In your Darklang canvas, you may want to configure:

- **CORS headers** - If calling from web browsers
- **Rate limiting** - To prevent abuse
- **Authentication** - For private/enterprise use

## 📊 Monitoring

### Health Checks

The API provides a health endpoint:

```bash
curl https://your-canvas-name.dlio.live/health
```

Expected response:
```json
{
  "status": "healthy",
  "service": "create-lamdera-app-darklang"
}
```

### Logging

Darklang provides built-in logging and monitoring:

1. View logs in the Darklang editor
2. Monitor request patterns and errors
3. Track API usage statistics

## 🔒 Security Considerations

### Rate Limiting

Consider implementing rate limiting for production use:

```darklang
let rateLimitCheck (clientId: String): Bool =
  // Implement rate limiting logic
  // Check requests per minute/hour per client
  true
```

### Authentication

For enterprise use, add authentication:

```darklang
let authenticateRequest (request): Bool =
  let apiKey = request.headers |> Dict.get "X-API-Key"
  // Validate API key
  apiKey == "your-secret-key"
```

### CORS

If calling from web browsers, configure CORS:

```darklang
let corsHeaders = {
  "Access-Control-Allow-Origin" = "*",
  "Access-Control-Allow-Methods" = "GET, POST, OPTIONS",
  "Access-Control-Allow-Headers" = "Content-Type"
}
```

## 🚀 Scaling

### Multiple Regions

Deploy to multiple Darklang regions for global coverage:

1. Create canvas in different regions
2. Use a load balancer or CDN
3. Update CLI to use region-aware URLs

### Caching

Implement caching for frequently requested templates:

```darklang
let templateCache = DB.set "template_cache" "base" baseTemplate
let getCachedTemplate (templateName: String) = 
  DB.get "template_cache" templateName
```

### Background Processing

For heavy operations, consider background processing:

```darklang
// Queue template generation for async processing
let queueTemplateGeneration (config: ProjectConfig) =
  Queue.push "template_generation" config
```

## 🔄 Updates and Maintenance

### Versioning

Track API versions in responses:

```darklang
Http.respond 200 {
  template = projectTemplate,
  version = "1.3.0-darklang",
  apiVersion = "v1"
}
```

### Rolling Updates

Darklang supports rolling updates:

1. Make changes in the editor
2. Test in a separate canvas first
3. Deploy changes incrementally

### Backup and Recovery

Darklang handles infrastructure:

- Automatic backups
- Point-in-time recovery
- Cross-region replication

## 📈 Analytics

### Usage Tracking

Track API usage patterns:

```darklang
let logUsage (config: ProjectConfig) =
  let usage = {
    timestamp = Date.now(),
    features = [
      ("tailwind", config.useTailwind),
      ("test", config.useTest),
      ("i18n", config.useI18n)
    ],
    packageManager = config.packageManager
  }
  DB.insert "usage_analytics" usage
```

### Feature Popularity

Monitor which features are most requested:

```darklang
let updateFeatureStats (config: ProjectConfig) =
  if config.useTailwind then
    DB.increment "feature_stats" "tailwind"
  if config.useTest then
    DB.increment "feature_stats" "test"
  if config.useI18n then
    DB.increment "feature_stats" "i18n"
```

## 🛠️ Troubleshooting

### Common Issues

1. **CORS Errors**: Add appropriate CORS headers
2. **Rate Limiting**: Implement and configure rate limits
3. **Large Responses**: Consider compression for large templates
4. **Timeout Issues**: Optimize template generation performance

### Debug Mode

Add debug endpoints for troubleshooting:

```darklang
[/debug/config GET]
let debugConfig (request) =
  Http.respond 200 {
    timestamp = Date.now(),
    version = "1.3.0-darklang",
    features = ["tailwind", "test", "i18n", "cursor"]
  }
```

### Error Handling

Implement comprehensive error handling:

```darklang
let handleError (error: String) (request) =
  Http.respond 500 {
    error = error,
    timestamp = Date.now(),
    requestId = request.headers |> Dict.get "X-Request-ID"
  }
```

## 📞 Support

For deployment issues:

1. Check Darklang documentation
2. Use Darklang community forums
3. Create GitHub issues for API-specific problems

## 🎯 Production Checklist

Before going to production:

- [ ] Health checks working
- [ ] All endpoints tested
- [ ] Error handling implemented
- [ ] Rate limiting configured
- [ ] Monitoring set up
- [ ] Security reviewed
- [ ] Performance tested
- [ ] Documentation updated
- [ ] CLI tool tested with production API
- [ ] Backup strategy confirmed