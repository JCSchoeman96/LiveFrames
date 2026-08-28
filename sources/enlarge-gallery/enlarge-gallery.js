import React, { useState, useRef, useCallback, useEffect } from "https://esm.sh/react";
import { createRoot }from "https://esm.sh/react-dom/client";
import {
  Gallery,
  GalleryMain,
  GalleryItem,
  GalleryNav,
  GalleryPagination,
  GalleryPaginationItem,
  useGallery,
} from "https://esm.sh/@wethegit/react-gallery@4.0.2";
console.clear();

const ITEMS = [
  {
    id: 1,
    src: "https://images.unsplash.com/photo-1448375240586-882707db888b?auto=format&fit=crop&w=1600&h=900&q=80",
    alt: "Forest path with light filtering through trees",
    title: "Into the Pines",
    description:
      "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nullam at posuere magna. Nam eros purus, congue pulvinar turpis pretium, vulputate interdum turpis. Vivamus non arcu.",
  },
  {
    id: 2,
    src: "https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?auto=format&fit=crop&w=1600&h=900&q=80",
    alt: "Rocky mountain peak against blue sky",
    title: "The High Country",
    description: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. ",
  },
  {
    id: 3,
    src: "https://images.unsplash.com/photo-1505118380757-91f5f5632de0?auto=format&fit=crop&w=1600&h=900&q=80",
    alt: "Ocean waves at sunset",
    title: "Last Light Offshore",
    description:
      "Praesent vel orci orci. Nam sed eleifend felis. Duis eget risus vel nisl feugiat semper eu ut ligula. Morbi eget lorem porttitor, gravida diam lobortis.",
  },
  {
    id: 4,
    src: "https://images.unsplash.com/photo-1519501025264-65ba15a82390?auto=format&fit=crop&w=1600&h=900&q=80",
    alt: "City skyline at night",
    title: "After Hours",
    description:
      "Ut pretium nibh vitae velit laoreet eleifend. Cras consectetur nisl elit, eu scelerisque ante placerat.",
  },
  {
    id: 5,
    src: "https://images.unsplash.com/photo-1509316785289-025f5b846b35?auto=format&fit=crop&w=1600&h=900&q=80",
    alt: "Desert sand dunes",
    title: "Sea of Sand",
    description:
      "Maecenas enim ex, pharetra ut efficitur accumsan, blandit in elit. Donec commodo sapien malesuada condimentum feugiat. Class aptent taciti sociosqu ad litora torquent per conubia.",
  },
  {
    id: 6,
    src: "https://images.unsplash.com/photo-1531366936337-7c912a4589a7?auto=format&fit=crop&w=1600&h=900&q=80",
    alt: "Northern lights over snowy landscape",
    title: "Solar Winds",
    description:
      "Ut scelerisque non nulla ac scelerisque. Nulla sollicitudin suscipit dolor vitae lacinia. Quisque id dapibus est. Aenean eget magna id urna cursus congue.",
  },
]

const TOTAL = ITEMS.length

const indexOfId = (id) => ITEMS.findIndex((item) => item.id === id)

function Slides({ thumbOrder }) {
  const { goToIndex } = useGallery()

  return (
    <GalleryMain
      className="track"
      renderGalleryItem={({ item, index, active }) => {
        // Strip slot comes from the queue, centered around the middle of the
        // screen. The active item isn't in the queue (indexOf -1), but its
        // offset is unused while the full-screen transform applies.
        const offset = thumbOrder.indexOf(item.id) - (thumbOrder.length - 1) / 2

        return (
          <GalleryItem
            key={item.id}
            index={index}
            active={active}
            className="item"
            data-active={String(active)}
          >
            <div className="slide" style={{ "--offset": offset }}>
              <img src={item.src} alt={item.alt} className="image" />
              {!active && (
                <button
                  type="button"
                  className="thumbButton"
                  tabIndex={-1}
                  onClick={() => goToIndex(index)}
                >
                  <span className="visuallyHidden">Show {item.title}</span>
                </button>
              )}
            </div>
          </GalleryItem>
        )
      }}
    />
  )
}

function ActiveContent({ thumbOrder }) {
  const { activeIndex, goToIndex } = useGallery()
  const item = ITEMS[activeIndex]

  return (
    <div className="rail">
      <div className="content" key={item.id}>
        <p className="kicker">
          {String(activeIndex + 1).padStart(2, "0")} / {String(TOTAL).padStart(2, "0")}
        </p>
        <h2 className="title">{item.title}</h2>
        <p className="description">{item.description}</p>
      </div>

      {/*
       * Deck-rotation nav: next pulls up the leftmost thumbnail, previous the
       * rightmost — which is the most recently viewed, since every change
       * pushes the outgoing item to the end of the strip. The queue never
       * empties, so neither direction ever disables.
       */}
      <div className="controls">
        <button
          type="button"
          className="navBtn"
          onClick={() => goToIndex(indexOfId(thumbOrder[thumbOrder.length - 1]))}
        >
          <svg
            width="20"
            height="20"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth="2.5"
            strokeLinecap="round"
            strokeLinejoin="round"
            aria-hidden="true"
          >
            <polyline points="15 18 9 12 15 6" />
          </svg>
          <span className="visuallyHidden">Previous</span>
        </button>
        <button
          type="button"
          className="navBtn"
          onClick={() => goToIndex(indexOfId(thumbOrder[0]))}
        >
          <svg
            width="20"
            height="20"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth="2.5"
            strokeLinecap="round"
            strokeLinejoin="round"
            aria-hidden="true"
          >
            <polyline points="9 18 15 12 9 6" />
          </svg>
          <span className="visuallyHidden">Next</span>
        </button>
      </div>
    </div>
  )
}

function EnlargeGallery() {
  // The thumbnail strip as a queue of item ids, left to right; the active
  // item is excluded. Every change removes the incoming item from the queue
  // and pushes the outgoing item onto the end.
  const [thumbOrder, setThumbOrder] = useState(() =>
    ITEMS.slice(1).map((item) => item.id)
  )

  const handleChange = useCallback(({ oldIndex, newIndex }) => {
    setThumbOrder((order) => [
      ...order.filter((id) => id !== ITEMS[newIndex].id),
      ITEMS[oldIndex].id,
    ])
  }, [])

  return (
    <div className="root">
      <Gallery
        items={ITEMS}
        draggable={false}
        className="gallery"
        onChange={handleChange}
      >
        <Slides thumbOrder={thumbOrder} />
        <ActiveContent thumbOrder={thumbOrder} />
      </Gallery>
    </div>
  )
}


const App = () => {
  return <EnlargeGallery />;
};

const container = document.getElementById("root");
const root = createRoot(container);
root.render(<App />);