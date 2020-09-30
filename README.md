# Concurrent-Game
Multiplayer game using Processing and Erlang

Multiplayer game developed using two independent modules: client and server.

- Client, written in Proessing (Java), deals with graphics and with communication with another players via sockets.

- Server, written in Erlang, is responsible for players interaction by processing motor functions of the game. Concurrency management with all objects present in the game. Saves all metadata of the game and sends it o client so information can be rendered.
