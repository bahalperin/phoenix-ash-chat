export const MessageInput = {
  mounted() {
    let timeoutId;
    this.el.addEventListener("input", () => {
      if (timeoutId) {
        clearTimeout(timeoutId);
      }
      timeoutId = setTimeout(() => {
        this.pushEvent("stop_typing");
      }, 2000);

      this.pushEvent("start_typing");
    });
  },
};
