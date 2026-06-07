# Jym App Backend

Professional Node.js backend with Firebase Admin SDK integration.

## Setup Instructions

1.  **Install Dependencies:**
    ```bash
    npm install
    ```

2.  **Firebase Service Account:**
    - Go to Firebase Console > Project Settings > Service Accounts.
    - Click "Generate new private key".
    - Rename the downloaded file to `firebase-service-account.json`.
    - Place it in the `backend/` root directory.

3.  **Environment Variables:**
    - Create a `.env` file based on `.env.example`.

4.  **Run the Server:**
    - Development: `npm run dev`
    - Production: `npm start`

## API Endpoints

### Auth
- `POST /api/auth/register`: Register with email, password, and name.
- `POST /api/auth/google-verify`: Verify Google ID Token and sync user data.

### User
- `GET /api/users/profile`: Get authenticated user's profile.
- `PUT /api/users/profile`: Update user profile information.

## Architecture
- `src/config`: Firebase and other configurations.
- `src/controllers`: Business logic for each resource.
- `src/routes`: API route definitions.
- `src/middlewares`: Security and authentication middlewares.
- `src/app.js`: Express app setup.
- `src/server.js`: Entry point to start the server.
