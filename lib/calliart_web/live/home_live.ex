defmodule CalliartWeb.HomeLive do
  use CalliartWeb, :live_view

  @editorials [
    %{title: "Bloom in Static", meta: "EDITORIAL · 2025", frames: [1.4, 0.7, 1.2, 0.7, 1.5]},
    %{title: "Salt & Silk", meta: "BEAUTY · 2025", frames: [0.7, 1.3, 0.7, 1.2]},
    %{title: "Noir Atelier", meta: "CAMPAIGN · 2024", frames: [1.5, 0.7, 1.3, 0.7, 1.2, 0.8]},
    %{title: "Wildflower", meta: "EDITORIAL · 2024", frames: [0.7, 1.4, 0.7, 1.2]},
    %{title: "After Hours", meta: "PORTRAIT · 2025", frames: [1.3, 0.7, 1.4, 0.7, 1.2]},
    %{title: "Concrete Muse", meta: "CAMPAIGN · 2025", frames: [0.8, 1.3, 0.7, 1.4]},
    %{title: "The Garden", meta: "EDITORIAL · 2025", frames: [1.2, 0.8, 1.1]},
    %{title: "A New Beginning", meta: "CAMPAIGN · 2024", frames: [0.6, 1.5, 0.9, 1.1, 1.4]},
    %{title: "The Journey Begins", meta: "EDITORIAL · 2025", frames: [1.1, 0.7, 1.2, 0.8]},
    %{title: "Urban Solitude", meta: "PORTRAIT · 2023", frames: [1.0, 1.1, 0.9]},
    %{title: "A Touch of Blue", meta: "BEAUTY · 2022", frames: [1.3, 0.7, 1.5, 0.8, 1.2, 0.6]},
    %{title: "Fragments", meta: "EDITORIAL · 2024", frames: [0.9, 1.2, 1.0, 0.8, 1.2]},
    %{title: "Reverie", meta: "PORTRAIT · 2025", frames: [1.4, 1.1]},
    %{title: "Serene Morning", meta: "BEAUTY · 2025", frames: [1.3, 0.7]},
    %{title: "Edge of Dusk", meta: "CAMPAIGN · 2023", frames: [1.2, 1.0, 0.7, 1.1]},
    %{title: "Chromatic Dreams", meta: "EDITORIAL · 2025", frames: [0.8, 1.5, 0.9, 1.1, 1.0, 0.7, 1.2]}
  ]

  @tones [
    ["#2c261f", "#16120d"],
    ["#27302b", "#141a16"],
    ["#322a22", "#1a140f"],
    ["#262430", "#15131a"],
    ["#2e2a26", "#181410"],
    ["#2a2520", "#15110c"]
  ]

  @angles [135, 42, 118, 160, 68, 100]

  # ── mount ──────────────────────────────────────────────────────────────────

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(ed: 0, index_open: false, about_open: false, editorials: build_editorials())
     |> derive()}
  end

  # ── navigation events ──────────────────────────────────────────────────────

  def handle_event("prev_ed", _, socket),
    do: {:noreply, go_ed(socket, socket.assigns.ed - 1)}

  def handle_event("next_ed", _, socket),
    do: {:noreply, go_ed(socket, socket.assigns.ed + 1)}

  def handle_event("go_ed", %{"ed" => raw}, socket),
    do: {:noreply, go_ed(socket, String.to_integer(raw))}

  # ── overlay events ─────────────────────────────────────────────────────────

  def handle_event("open_index", _, socket),
    do: {:noreply, assign(socket, index_open: true, about_open: false)}

  def handle_event("close_index", _, socket),
    do: {:noreply, assign(socket, index_open: false)}

  def handle_event("open_about", _, socket),
    do: {:noreply, assign(socket, about_open: true, index_open: false)}

  def handle_event("close_about", _, socket),
    do: {:noreply, assign(socket, about_open: false)}

  def handle_event("close_overlays", _, socket),
    do: {:noreply, assign(socket, index_open: false, about_open: false)}

  # ── orchestration ──────────────────────────────────────────────────────────

  defp go_ed(socket, ei) do
    n = Integer.mod(ei, length(@editorials))

    socket
    |> assign(ed: n, index_open: false)
    |> derive()
    |> push_event("ca:ed_changed", %{ed: n})
  end

  defp derive(socket) do
    %{ed: ed} = socket.assigns
    ce = Enum.at(@editorials, ed)
    frame_count = length(ce.frames)

    assign(socket,
      page_title: "calliart",
      cur_title: ce.title,
      cur_meta: pad(ed + 1) <> " — " <> ce.meta,
      frame_count: frame_count,
      frame_counter: "01 / " <> pad(frame_count),
      ed_counter: "Editorial " <> pad(ed + 1) <> " · " <> to_string(length(@editorials)),
      track_transform: "translateX(-#{ed * 100}vw)"
    )
  end

  # ── editorial presentation ─────────────────────────────────────────────────

  defp build_editorials do
    @editorials |> Enum.with_index() |> Enum.map(&build_editorial/1)
  end

  defp build_editorial({ed, ei}) do
    %{
      title: ed.title,
      meta: pad(ei + 1) <> " — " <> ed.meta,
      frame_note: "#{length(ed.frames)} frames",
      cover_style: cover_style(hd(ed.frames), grad(gi_for(ei, 0))),
      frames: ed.frames |> Enum.with_index() |> Enum.map(&build_frame(ed.title, &1, ei)),
      ed_index: ei
    }
  end

  defp build_frame(title, {_ar, fi}, ei) do
    g = grad(gi_for(ei, fi))

    style =
      "height:100vh;width:100%;display:flex;align-items:center;" <>
        "justify-content:center;background:#{g};scroll-snap-align:start;"

    %{style: style, label: title <> " — " <> pad(fi + 1)}
  end

  defp cover_style(ar, grad) do
    "width:100%;aspect-ratio:#{Float.round(1 / ar, 3)};background:#{grad};" <>
      "display:flex;align-items:center;justify-content:center;"
  end

  defp grad(seed) do
    [c1, c2] = Enum.at(@tones, rem(seed, length(@tones)))
    a = Enum.at(@angles, rem(seed, length(@angles)))
    "linear-gradient(#{a}deg,#{c1},#{c2})"
  end

  defp gi_for(ei, fi) do
    @editorials |> Enum.take(ei) |> Enum.map(&length(&1.frames)) |> Enum.sum() |> Kernel.+(fi)
  end

  defp pad(n) when n < 10, do: "0#{n}"
  defp pad(n), do: "#{n}"
end
