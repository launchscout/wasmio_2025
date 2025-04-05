import publishMessage from 'publish-message';

const secretWord = 'WAT';

export function addMessage(message) {
  if (message === secretWord) {
    throw new Error('You said the secret word aaaaaa!!!');
  }
  publishMessage(message);
  publishMessage("And here is a message from a wasm component!!");
  return message;
}

export function init() {
  return ["You joined the wasm component chat!"];
}

export function messageAdded(message, messages) {
  return [...messages, message];
}
