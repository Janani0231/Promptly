# Mini TaskHub - Flutter Task App

A Flutter task management application using Supabase for authentication and data storage.

## Supabase Setup

### Setting up Storage for Profile Images

1. Go to the Supabase Dashboard and select your project
2. Navigate to the Storage section in the sidebar
3. Click "New Bucket" and create a bucket named `avatars`
4. Set the bucket to be `public` (or set appropriate security policies)
5. Create RLS (Row Level Security) policies for the bucket:

### Storage RLS Policies

Create the following policies for the `storage.objects` table:

#### 1. Allow users to view their own avatars and public avatars

```sql
CREATE POLICY "Allow users to view their own avatars"
ON storage.objects
FOR SELECT
USING (
  bucket_id = 'avatars' AND
  (auth.uid() = owner_id::uuid OR owner_id IS NULL)
);
```

#### 2. Allow authenticated users to upload avatars

```sql
CREATE POLICY "Allow users to upload avatars"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'avatars' AND
  owner_id::uuid = auth.uid()
);
```

#### 3. Allow users to update their own avatars

```sql
CREATE POLICY "Allow users to update their own avatars"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
  bucket_id = 'avatars' AND
  owner_id::uuid = auth.uid()
);
```

#### 4. Allow users to delete their own avatars

```sql
CREATE POLICY "Allow users to delete their own avatars"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'avatars' AND
  owner_id::uuid = auth.uid()
);
```

## Features

- User authentication (login, signup)
- Profile management with profile image upload
- Task creation and management
- Mark tasks as complete/incomplete
- Delete tasks
- Dark/light theme toggle

## Hot Reload vs Hot Restart

- **Hot Reload**: Quickly updates the UI with code changes while preserving the app state. Useful for making UI adjustments.
- **Hot Restart**: Completely restarts the app, resetting all state. Use when making significant changes to app logic or when hot reload doesn't properly reflect changes.

## Dependencies

- flutter
- supabase_flutter: Backend database and authentication
- provider: State management
- flutter_slidable: For swipeable task items
- uuid: For generating unique IDs
- shared_preferences: For local storage
- image_picker: For selecting profile images

## How to Run

1. Clone the repository
2. Run `flutter pub get` to install dependencies
3. Run `flutter run` to start the app
