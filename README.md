# skribbl

A new Flutter project.

A Cross Platform - Web, Android & iOS App multiplayer doodling & guessing game.

## Tech Stack
Client: Flutter, socket_io_client

Server: Node, Express, Socket.io, Mongoose
## Features
Creating Room
Joining Room
Doodling Features (Everyone In Room Can see)
Changing Width of Pen
Changing Colour of Pen
Clearing off the Screen
Drawing
Generating Random Words
Chatting In Room
Identifying Correct Words
Switching Turns
Changing Rounds

## Screenshots
<img src="https://github.com/thatboyrohit/draw-the-phrase/blob/master/screenshots/create%26join_screen.png" width="200" />  <img src="https://github.com/thatboyrohit/draw-the-phrase/blob/master/screenshots/main_screen.png" width="200" />  <img src="https://github.com/thatboyrohit/draw-the-phrase/blob/master/screenshots/guessed_word_screen.png" width="200" />

## Environment Variables

To run this project, you will need to add the following environment variables to your .env file

`MONGODB_URL`: `Your MongoDB URI Generated from MongoDB Atlas`

Make sure to replace <yourip> in `lib/screens/paint_screen.dart` with your IP address.

  
## Run Locally

Clone the project

```bash
  git clone https://github.com/RivaanRanawat/cuadro
```

Go to the project directory

```bash
  cd cuadro
```

Install dependencies (Client Side)
```bash
flutter pub get
```

Install dependencies (Server Side)

```bash
cd server && npm install
```

Start the server

```bash
npm run dev
```
