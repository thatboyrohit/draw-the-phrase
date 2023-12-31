const { Socket } = require("dgram");
const express = require("express");
var http = require("http");
const app = express();
const port = process.env.PORT || 5000;
var server = http.createServer(app);
const Room = require("./models/Room");
const mongoose = require("mongoose");
const getWord = require('./api/getWord');
const { SocketAddress } = require("net");

var io = require("socket.io")(server);

//middleware
app.use(express.json());

//connect to our MongoDB
const DB = 'mongodb+srv://thatboyrohit:Bleh%402004@cluster0.ucp3yaq.mongodb.net/?retryWrites=true&w=majority';

mongoose.connect(DB).then(() => {
    console.log('Connection successful!')
}).catch((e) => {
    console.log(e);
})

io.on('connection', (socket) => { // Changed Socket to socket
    console.log("connected");

    // CREATE GAME CALLBACK
    socket.on('create-game', async ({ nickname, name, occupancy, maxRounds }) => { // Changed Socket to socket
        try {
            const existingRoom = await Room.findOne({ name });
            if (existingRoom) {
                socket.emit("notCorrectGame", "Room with that name already exists");
                return;
            }
            let room = new Room();
            const word = getWord();
            room.word = word;
            room.name = name;
            room.occupancy = occupancy;
            room.maxRounds = maxRounds;

            let player = {
                socketID: socket.id,
                nickname,
                isPartyleader: true,
            }

            room.players.push(player);
            room = await room.save();
            socket.join(name);
            io.to(name).emit('updateRoom', room);
        } catch (err) {
            console.log(err);
        }
    });

    // JOIN GAME CALLBACK
    socket.on('join-game', async ({ nickname, name }) => {
        try {
            let room = await Room.findOne({ name });
            if (!room) {
                socket.emit('notCorrectGame', 'Please enter a valid room name'); // Changed Socket to socket
                return;
            }
            if (room.isJoin) {
                let player = {
                    socketID: socket.id,
                    nickname,
                }
                room.players.push(player);
                socket.join(name);
                if (room.players.length == room.occupancy) {
                    room.isJoin = false;
                }
                room.turn = room.players[room.turnIndex];
                room = await room.save();
                io.to(name).emit('updateRoom', room);
            } else {
                socket.emit('notCorrectGame', 'The game is in progress, please try again later!'); // Changed Socket to socket
            }
        } catch (err) {
            console.log(err);
        }
    });

    socket.on('msg', async(data) =>{
        console.log(data);
        try{
            if(data.msg === data.word){
                let room = await Room.find({name : data.roomName});
                let userPlayer = room[0].players.filter(
                    (player) => player.nickname === data.username
                )
                if(data.timeTaken !== 0){
                   userPlayer[0].points += Math.round((200/data.timeTaken)*10);
                }
                room  = await room[0].save();
                io.to(data.roomName).emit('msg' ,{
                    username : data.username,
                    msg: 'Guessed it!',
                    guessedUserCtr : data.guessedUserCtr + 1,
                })
            } else{
                io.to(data.roomName).emit('msg' ,{
                    username : data.username,
                    msg: data.msg,
                    guessedUserCtr : data.guessedUserCtr,
                })
            }
        } catch(err){
          console.log(err.toString());
        }
    });

    socket.on('change-turn', async (name) => {
        try {
            let room = await Room.findOne({ name });
            let idx = room.turnIndex;
            if (idx + 1 === room.players.length) {
                room.currentRound += 1;
            }
            if (room.currentRound <= room.maxRounds) {
                const word = getWord();
                room.word = word;
                room.turnIndex = (idx + 1) % room.players.length;
                room.turn = room.players[room.turnIndex];
                room = await room.save();
                io.to(name).emit('change-turn', room);
            } else {
                // Handle when the current round exceeds maxRounds
            }
        } catch (err) {
            console.log(err);
        }
    });
    // White board socket
socket.on('paint' , ({details , roomName}) =>{
    io.to(roomName).emit('points' , {details: details})
});
//Color socket
socket.on('color-change', ({color, roomName}) => {
    io.to(roomName).emit('color-change', color);
});

 //Stroke socker
 socket.on('stroke-width' ,({value , roomName}) =>{
    io.to(roomName).emit('stroke-width' , value);
 });
 //Clear screen
 socket.on('clean-screen' , (roomName)=>{
    io.to(roomName).emit('clean-screen', '');
 });

 //
});



// listening to request or starting the server
server.listen(port, "0.0.0.0", () => {
    console.log('Server started, running on port ' + port);
});