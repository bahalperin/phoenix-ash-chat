const input = document.getElementById('message-input');                                           

export const MessageForm = {
  updated() {
    if (document.getElementsByClassName('invalid-feedback').length == 0) {
      input.value = '';
    }
  }
}