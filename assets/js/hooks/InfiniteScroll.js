export const InfiniteScroll = {
  loadMore(entries) {
    const target = entries[0];
    if (target.isIntersecting) {
      this.pushEvent(this.eventName, {});
    }
  },
  mounted() {
    this.eventName = this.el.dataset.eventName
    this.observer = new IntersectionObserver(
      (entries) => this.loadMore(entries),
      {
        root: null,
        rootMargin: "100px",
        threshold: 1,
      }
    );
    this.observer.observe(this.el);
  },
  destroyed() {
    this.observer.unobserve(this.el);
  }
};