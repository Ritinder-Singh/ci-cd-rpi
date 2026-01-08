# Frontend Web Application

Flutter Web frontend for the CI/CD platform running on Raspberry Pi.

## Features

- Responsive Material Design UI
- Real-time system metrics display
- CPU, memory, and disk usage monitoring
- API integration with backend
- Error handling and loading states
- Auto-refresh capability

## Architecture

### Two-Stage Docker Build
1. **Stage 1**: Build Flutter web app using Flutter SDK
2. **Stage 2**: Serve with Nginx for optimal performance

### Nginx Configuration
- Serves Flutter static files
- Reverse proxies `/api/*` to backend service
- Implements SPA routing fallback
- Gzip compression for assets
- Caching strategy for static resources

## Local Development

### Prerequisites
- Flutter SDK 3.10+
- Dart SDK (included with Flutter)
- Chrome or Edge browser

### Setup

1. Install Flutter:
```bash
# Visit: https://flutter.dev/docs/get-started/install
```

2. Get dependencies:
```bash
cd frontend
flutter pub get
```

3. Run in development mode:
```bash
flutter run -d chrome
```

Or for web server mode:
```bash
flutter run -d web-server --web-port 8080
```

The app will be available at http://localhost:8080

### Running Tests

```bash
flutter test
```

With coverage:
```bash
flutter test --coverage
```

### Building for Production

```bash
flutter build web --release
```

Output will be in `build/web/`

## Docker Build

Build the Docker image:
```bash
docker build -t registry.lan:5000/web:latest .
```

Run the container:
```bash
docker run -d -p 80:80 --name web registry.lan:5000/web:latest
```

## Environment Variables

The app uses relative URLs for API calls, which are proxied by Nginx:
- `/api/v1/hello` → `http://backend:5001/api/v1/hello`
- `/api/v1/info` → `http://backend:5001/api/v1/info`
- `/health` → `http://backend:5001/health`

## CI/CD Pipeline

The Jenkins pipeline (`Jenkinsfile`) performs:
1. Checkout code
2. Run tests (if Flutter available in Jenkins)
3. Build Docker image (includes Flutter build)
4. Tag with build number and latest
5. Push to local registry
6. Deploy via docker-compose
7. Verify frontend and API proxy

## Project Structure

```
frontend/
├── lib/
│   ├── main.dart                # App entry point
│   ├── screens/
│   │   └── home_screen.dart     # Main dashboard screen
│   └── services/
│       └── api_service.dart     # Backend API client
├── web/
│   └── index.html               # Web entry point
├── test/
│   └── widget_test.dart         # Widget tests
├── Dockerfile                   # Two-stage build
├── nginx.conf                   # Nginx configuration
├── pubspec.yaml                 # Dependencies
└── README.md                    # This file
```

## Features Breakdown

### Home Screen
- Displays welcome message from backend
- Shows real-time system metrics:
  - CPU usage with color coding
  - Memory usage with color coding
  - Disk usage with color coding
  - Environment name
  - Hostname
- Refresh button to reload data
- Error handling with retry functionality

### API Service
- Handles HTTP requests to backend
- Implements error handling
- Uses relative URLs for Nginx proxy

## Troubleshooting

### Port 80 requires sudo
On Linux, port 80 requires elevated privileges. Either:
- Use port 8080: `docker run -p 8080:80 ...`
- Or use sudo: `sudo docker run -p 80:80 ...`

### CORS errors in development
The backend has CORS enabled for all origins. If you still see CORS errors:
1. Check backend is running
2. Verify API URL in api_service.dart
3. Check browser console for specific error

### Flutter build fails in Docker
- Ensure sufficient memory (at least 2GB)
- Check Docker/Podman logs: `docker logs <container>`
- Build may take 5-10 minutes on Raspberry Pi

### Nginx not proxying API calls
1. Check nginx.conf is correctly copied
2. Verify backend service name in docker-compose
3. Check nginx logs: `docker logs web`

## Performance Tips

- Flutter web apps work best in Chrome/Edge
- Use `--web-renderer html` for better compatibility
- Gzip compression is enabled for all assets
- Static assets are cached for 1 year

## License

MIT
