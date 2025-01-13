-module(windsurf_demo_handler).
-behavior(cowboy_handler).

-export([init/2]).

init(Req0, State) ->
    Html = <<"<!DOCTYPE html>
<html>
    <head>
        <meta charset=\"UTF-8\">
        <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">
        <title>Windsurf Demo Chat</title>
        <style>
            body {
                font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
                margin: 0;
                padding: 20px;
                background: #f5f7fa;
                color: #2d3748;
                height: 100vh;
                display: flex;
                flex-direction: column;
            }

            .container {
                max-width: 800px;
                margin: 0 auto;
                width: 100%;
                background: white;
                border-radius: 12px;
                box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
                padding: 20px;
                flex-grow: 1;
                display: flex;
                flex-direction: column;
            }

            h1 {
                text-align: center;
                color: #2b6cb0;
                margin-bottom: 1.5rem;
                font-weight: 600;
            }

            #username-container {
                display: flex;
                flex-direction: column;
                align-items: center;
                gap: 1rem;
                padding: 2rem;
                background: #ebf4ff;
                border-radius: 8px;
                margin-bottom: 1rem;
            }

            #messages {
                flex-grow: 1;
                overflow-y: auto;
                padding: 1rem;
                margin-bottom: 1rem;
                border: 1px solid #e2e8f0;
                border-radius: 8px;
                background: #f8fafc;
            }

            #input-container {
                display: none;
                gap: 0.5rem;
                margin-top: auto;
            }

            input[type='text'] {
                flex-grow: 1;
                padding: 0.75rem 1rem;
                border: 2px solid #e2e8f0;
                border-radius: 6px;
                font-size: 1rem;
                transition: border-color 0.2s;
            }

            input[type='text']:focus {
                outline: none;
                border-color: #4299e1;
                box-shadow: 0 0 0 3px rgba(66, 153, 225, 0.2);
            }

            button {
                padding: 0.75rem 1.5rem;
                background: #4299e1;
                color: white;
                border: none;
                border-radius: 6px;
                font-weight: 600;
                cursor: pointer;
                transition: background-color 0.2s;
            }

            button:hover {
                background: #3182ce;
            }

            button:active {
                background: #2b6cb0;
            }

            .message {
                margin: 0.5rem 0;
                padding: 0.75rem 1rem;
                border-radius: 8px;
                max-width: 80%;
                word-wrap: break-word;
            }

            .message.system {
                background: #e2e8f0;
                color: #4a5568;
                text-align: center;
                max-width: 100%;
                font-style: italic;
            }

            .message.self {
                background: #4299e1;
                color: white;
                margin-left: auto;
                border-bottom-right-radius: 2px;
            }

            .message.other {
                background: #edf2f7;
                color: #2d3748;
                margin-right: auto;
                border-bottom-left-radius: 2px;
            }

            .username {
                font-size: 0.875rem;
                margin-bottom: 0.25rem;
                font-weight: 600;
            }

            .message.self .username {
                color: #e2e8f0;
            }

            .message.other .username {
                color: #4a5568;
            }

            @media (max-width: 640px) {
                body {
                    padding: 10px;
                }

                .container {
                    border-radius: 8px;
                    padding: 15px;
                }

                .message {
                    max-width: 90%;
                }
            }
        </style>
    </head>
    <body>
        <div class=\"container\">
            <h1>Windsurf Chat</h1>
            <div id=\"username-container\">
                <input type=\"text\" id=\"username-input\" placeholder=\"Enter your username\" autofocus>
                <button onclick=\"setUsername()\">Join Chat</button>
            </div>
            <div id=\"messages\"></div>
            <div id=\"input-container\">
                <input type=\"text\" id=\"message-input\" placeholder=\"Type your message...\" onkeypress=\"if(event.key === 'Enter') sendMessage()\">
                <button onclick=\"sendMessage()\">Send</button>
            </div>
        </div>
        <script>
            let ws = null;
            let username = '';
            
            function setUsername() {
                const input = document.getElementById('username-input');
                const inputUsername = input.value.trim();
                if (inputUsername) {
                    username = inputUsername;
                    document.getElementById('username-container').style.display = 'none';
                    document.getElementById('input-container').style.display = 'flex';
                    connectWebSocket(username);
                } else {
                    alert('Please enter a username');
                }
            }
            
            function connectWebSocket(username) {
                const wsUrl = new URL('/ws', window.location.href);
                wsUrl.protocol = wsUrl.protocol.replace('http', 'ws');
                wsUrl.searchParams.append('username', username);
                console.log('Connecting with URL:', wsUrl.href);
                ws = new WebSocket(wsUrl.href);
                
                ws.onopen = function() {
                    console.log('Connected to WebSocket with username:', username);
                    addSystemMessage('Connected to chat as: ' + username);
                };
                
                ws.onclose = function() {
                    console.log('Disconnected from WebSocket');
                    addSystemMessage('Disconnected from chat');
                };
                
                ws.onmessage = function(event) {
                    const data = JSON.parse(event.data);
                    addMessage(data.message, data.username, username === data.username);
                };
            }
            
            function sendMessage() {
                const input = document.getElementById('message-input');
                const message = input.value.trim();
                if (message && ws && ws.readyState === WebSocket.OPEN) {
                    ws.send(message);
                    input.value = '';
                }
            }
            
            function addMessage(message, msgUsername, isSelf) {
                const messagesDiv = document.getElementById('messages');
                const messageDiv = document.createElement('div');
                messageDiv.className = `message ${isSelf ? 'self' : 'other'}`;
                
                const usernameDiv = document.createElement('div');
                usernameDiv.className = 'username';
                usernameDiv.textContent = msgUsername;
                
                const messageContent = document.createElement('div');
                messageContent.className = 'message-content';
                messageContent.textContent = message;
                
                messageDiv.appendChild(usernameDiv);
                messageDiv.appendChild(messageContent);
                messagesDiv.appendChild(messageDiv);
                messagesDiv.scrollTop = messagesDiv.scrollHeight;
            }
            
            function addSystemMessage(message) {
                const messagesDiv = document.getElementById('messages');
                const messageDiv = document.createElement('div');
                messageDiv.className = 'message system';
                messageDiv.textContent = message;
                messagesDiv.appendChild(messageDiv);
                messagesDiv.scrollTop = messagesDiv.scrollHeight;
            }

            document.getElementById('username-input').addEventListener('keypress', function(e) {
                if (e.key === 'Enter') {
                    setUsername();
                }
            });
        </script>
    </body>
</html>">>,
    {ok, cowboy_req:reply(200,
        #{<<"content-type">> => <<"text/html">>},
        Html,
        Req0),
    State}.
