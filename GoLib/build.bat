go build -o ./bin/multiplayer.a -buildmode=c-archive main.go
cl /MD /c multiplayer.c /Fobin\ /link ./bin/multiplayer.a
cl /LD /MD /Fe"./bin/multiplayer.dll" /Fo"./bin/multiplayer.obj" multiplayer.c /link /DEF:multiplayer.def ./bin/multiplayer.a /LIBPATH:C:\MinGW\lib
PAUSE