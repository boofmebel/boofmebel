const state = {
  filter: "all",
  sort: "popular",
  selectedProduct: null,
  selectedFabric: null,
  cart: loadCart(),
  reviews: [...GLOBAL_REVIEWS],
};

const els = {};

document.addEventListener("DOMContentLoaded", () => {
  window.scrollTo(0, 0);
  cacheElements();
  initThemeToggle();
  bindFilters();
  bindHeroCtas();
  bindDeliveryCalc();
  bindCartControls();
  bindCheckout();
  bindReviewForm();
  renderProducts();
  renderCart();
  renderGlobalReviews();
});

function cacheElements() {
  els.grid = document.getElementById("products-grid");
  els.chips = document.querySelectorAll(".chip");
  els.sortSelect = document.getElementById("sort-select");
  els.modal = document.getElementById("product-modal");
  els.modalImage = document.getElementById("modal-image");
  els.modalThumbs = document.getElementById("modal-thumbs");
  els.modalTitle = document.getElementById("modal-title");
  els.modalBadge = document.getElementById("modal-badge");
  els.modalPrice = document.getElementById("modal-price");
  els.modalOld = document.getElementById("modal-oldprice");
  els.modalDesc = document.getElementById("modal-desc");
  els.modalFabrics = document.getElementById("modal-fabrics");
  els.modalSpecs = document.getElementById("modal-specs");
  els.modalDim = document.getElementById("modal-dim");
  els.modalQty = document.getElementById("modal-qty");
  els.modalAdd = document.getElementById("modal-add");
  els.modalClose = document.getElementById("close-modal");
  els.drawer = document.getElementById("cart-drawer");
  els.cartItems = document.getElementById("cart-items");
  els.cartTotal = document.getElementById("cart-total");
  els.cartSummary = document.getElementById("cart-summary");
  els.deliveryQuote = document.getElementById("delivery-quote");
  els.checkoutForm = document.getElementById("checkout-form");
  els.checkoutStatus = document.getElementById("checkout-status");
  els.reviewList = document.getElementById("reviews-list");
  els.reviewForm = document.getElementById("review-form");
  els.reviewStatus = document.getElementById("review-status");
}

function bindFilters() {
  els.chips.forEach((chip) =>
    chip.addEventListener("click", () => {
      els.chips.forEach((c) => c.classList.remove("active"));
      chip.classList.add("active");
      state.filter = chip.dataset.filter;
      renderProducts();
    })
  );
  els.sortSelect?.addEventListener("change", () => {
    state.sort = els.sortSelect.value;
    renderProducts();
  });
}

function initThemeToggle() {
  const btn = document.getElementById("theme-toggle");
  if (!btn) return;
  const saved = localStorage.getItem("theme");
  if (saved === "dark") document.body.classList.add("dark-theme");
  updateIcon();
  btn.onclick = () => {
    document.body.classList.toggle("dark-theme");
    const mode = document.body.classList.contains("dark-theme") ? "dark" : "light";
    localStorage.setItem("theme", mode);
    updateIcon();
  };
  function updateIcon() {
    btn.textContent = document.body.classList.contains("dark-theme") ? "☀️" : "🌙";
  }
}

function bindHeroCtas() {
  document.getElementById("cta-choose").onclick = () => scrollToId("catalog");
  document.getElementById("cta-delivery").onclick = () => scrollToId("delivery");
  document.getElementById("cta-call").onclick = () => scrollToId("checkout");
}

function bindDeliveryCalc() {
  document.getElementById("delivery-calc").onclick = async () => {
    const address = document.getElementById("delivery-address").value.trim();
    if (!address) {
      showQuote("Укажите адрес для расчёта", "error");
      return;
    }
    showQuote("Считаем тариф...", "info");
    const quote = await mockDelivery(address);
    showQuote(`Доставка ~${formatPrice(quote.price)} • срок ${quote.eta}`, "success");
  };
}

function bindCartControls() {
  document.getElementById("open-cart").onclick = () => toggleCart(true);
  document.getElementById("close-cart").onclick = () => toggleCart(false);
  document.getElementById("go-checkout").onclick = () => scrollToId("checkout");
}

function bindCheckout() {
  els.checkoutForm.addEventListener("submit", async (e) => {
    e.preventDefault();
    if (!state.cart.length) {
      setCheckoutStatus("Корзина пуста", "error");
      return;
    }
    const form = new FormData(els.checkoutForm);
    const payload = {
      name: form.get("name"),
      phone: form.get("phone"),
      email: form.get("email"),
      address: form.get("address"),
      comment: form.get("comment"),
      pay: form.get("pay"),
      items: state.cart,
      total: getCartTotal(),
    };
    setCheckoutStatus("Проверяем корзину и сумму...", "info");
    await sleep(400);
    const payment = await mockPayment(payload);
    if (payment.status !== "paid") {
      setCheckoutStatus("Оплата не прошла. Попробуйте ещё раз.", "error");
      return;
    }
    const delivery = await mockCreateDelivery(payload.address, payload.items);
    setCheckoutStatus(
      `Оплачено. Доставка создана: №${delivery.id}, срок ${delivery.eta}. Трек: ${delivery.tracking}`,
      "success"
    );
    state.cart = [];
    saveCart();
    renderCart();
  });
}

function bindReviewForm() {
  els.reviewForm.addEventListener("submit", (e) => {
    e.preventDefault();
    const form = new FormData(els.reviewForm);
    const entry = {
      author: form.get("author").trim(),
      rating: Number(form.get("rating") || 5),
      text: form.get("text").trim(),
      date: new Date().toISOString().slice(0, 10),
    };
    if (!entry.author || !entry.text) {
      setReviewStatus("Заполните имя и отзыв", "error");
      return;
    }
    state.reviews.unshift(entry);
    els.reviewForm.reset();
    renderGlobalReviews();
    setReviewStatus("Отзыв отправлен на модерацию (демо).", "success");
  });
}

function renderProducts() {
  let items =
    state.filter === "all"
      ? [...PRODUCTS]
      : PRODUCTS.filter((p) => p.category === state.filter);

  items = applySort(items, state.sort);
  els.grid.innerHTML = "";
  items.forEach((product) => {
    const card = document.createElement("div");
    card.className = "card";
    card.onclick = () => openProduct(product.id);
    card.innerHTML = `
      <img src="${product.images[0]}" alt="${product.name}">
      <div class="card-title-row">
        <div>
          <p class="meta">${product.category === "uglovoy" ? "Угловой диван" : product.category === "kreslo" ? "Кресло" : "Диван"}</p>
          <h3 style="margin:4px 0;">${product.name}</h3>
        </div>
        <span class="badge">${product.badge}</span>
      </div>
      <p class="price">${formatPrice(product.price)} ${product.oldPrice ? `<span class="oldprice">${formatPrice(product.oldPrice)}</span>` : ""}</p>
      <p class="meta">${product.short}</p>
    `;
    els.grid.appendChild(card);
  });
}

function openProduct(id) {
  const product = PRODUCTS.find((p) => p.id === id);
  if (!product) return;
  state.selectedProduct = product;
  state.selectedFabric = product.fabrics[0]?.id || null;
  els.modalTitle.textContent = product.name;
  els.modalBadge.textContent = product.badge || "";
  els.modalDesc.textContent = product.description;
  els.modalPrice.textContent = formatPrice(getCurrentPrice(product));
  els.modalOld.textContent = product.oldPrice ? formatPrice(product.oldPrice) : "";
  els.modalOld.style.display = product.oldPrice ? "inline" : "none";
  els.modalQty.value = 1;
  setModalImage(product.images[0]);
  renderThumbs(product);
  renderFabrics(product);
  renderSpecs(product);
  renderDims(product);
  els.modal.classList.remove("hidden");
  els.modalAdd.onclick = () => {
    addToCart(product, state.selectedFabric, Number(els.modalQty.value || 1));
    toggleCart(true);
    els.modal.classList.add("hidden");
  };
  els.modalClose.onclick = () => els.modal.classList.add("hidden");
  els.modal.addEventListener("click", (e) => {
    if (e.target === els.modal) els.modal.classList.add("hidden");
  });
}

function renderThumbs(product) {
  els.modalThumbs.innerHTML = "";
  product.images.forEach((src, idx) => {
    const img = document.createElement("img");
    img.src = src;
    img.alt = product.name;
    img.className = idx === 0 ? "active" : "";
    img.onclick = () => {
      setModalImage(src);
      els.modalThumbs.querySelectorAll("img").forEach((t) => t.classList.remove("active"));
      img.classList.add("active");
    };
    els.modalThumbs.appendChild(img);
  });
}

function renderFabrics(product) {
  els.modalFabrics.innerHTML = "";
  product.fabrics.forEach((fabric) => {
    const btn = document.createElement("div");
    btn.className = "fabric" + (fabric.id === state.selectedFabric ? " active" : "");
    btn.innerHTML = `<span class="dot" style="background:${fabric.color}"></span>${fabric.name}${fabric.priceDelta ? ` (+${formatPrice(fabric.priceDelta)})` : ""}`;
    btn.onclick = () => {
      state.selectedFabric = fabric.id;
      els.modalFabrics.querySelectorAll(".fabric").forEach((f) => f.classList.remove("active"));
      btn.classList.add("active");
      els.modalPrice.textContent = formatPrice(getCurrentPrice(product));
    };
    els.modalFabrics.appendChild(btn);
  });
}

function renderSpecs(product) {
  const { frame, filler, warranty, cover } = product.specs;
  els.modalSpecs.innerHTML = `
    <div><strong>Каркас</strong><br>${frame}</div>
    <div><strong>Наполнение</strong><br>${filler}</div>
    <div><strong>Гарантия</strong><br>${warranty}</div>
    <div><strong>Чехлы</strong><br>${cover}</div>
  `;
}

function renderDims(product) {
  const { width, depth, height, sleep, weight } = product.dimensions;
  els.modalDim.innerHTML = `
    <div><strong>Ширина</strong><br>${width} см</div>
    <div><strong>Глубина</strong><br>${depth} см</div>
    <div><strong>Высота</strong><br>${height} см</div>
    <div><strong>Спальное</strong><br>${sleep}</div>
    <div><strong>Вес</strong><br>${weight} кг</div>
  `;
}

function setModalImage(src) {
  els.modalImage.src = src;
}

function addToCart(product, fabricId, qty = 1) {
  const key = `${product.id}-${fabricId || "base"}`;
  const price = getCurrentPrice(product, fabricId);
  const existing = state.cart.find((i) => i.key === key);
  if (existing) {
    existing.qty += qty;
  } else {
    state.cart.push({
      key,
      productId: product.id,
      name: product.name,
      fabricId,
      fabricName: product.fabrics.find((f) => f.id === fabricId)?.name || "Базовая ткань",
      price,
      image: product.images[0],
      qty,
      weight: product.dimensions.weight,
    });
  }
  saveCart();
  renderCart();
}

function renderCart() {
  els.cartItems.innerHTML = "";
  state.cart.forEach((item) => {
    const wrap = document.createElement("div");
    wrap.className = "cart-item";
    wrap.innerHTML = `
      <img src="${item.image}" alt="${item.name}">
      <div>
        <div class="meta">${item.fabricName}</div>
        <div>${item.name}</div>
        <div class="cart-meta">${formatPrice(item.price)} • ${item.weight} кг</div>
      </div>
      <div class="cart-actions">
        <input type="number" min="1" value="${item.qty}">
        <button class="icon-button" aria-label="Удалить">×</button>
      </div>
    `;
    const qtyInput = wrap.querySelector("input");
    qtyInput.onchange = () => {
      item.qty = Math.max(1, Number(qtyInput.value || 1));
      saveCart();
      renderCart();
    };
    wrap.querySelector("button").onclick = () => {
      state.cart = state.cart.filter((i) => i.key !== item.key);
      saveCart();
      renderCart();
    };
    els.cartItems.appendChild(wrap);
  });
  els.cartTotal.textContent = formatPrice(getCartTotal());
  els.cartSummary.innerHTML = `
    <h3>Состав заказа</h3>
    ${state.cart
      .map(
        (i) =>
          `<div class="meta">${i.name} — ${i.fabricName} — ${i.qty} шт • ${formatPrice(
            i.price * i.qty
          )}</div>`
      )
      .join("") || "<p class='meta'>Корзина пуста</p>"}
    <div class="quote">Итого: <strong>${formatPrice(getCartTotal())}</strong></div>
  `;
}

function toggleCart(open) {
  if (open) els.drawer.classList.add("open");
  else els.drawer.classList.remove("open");
}

function renderGlobalReviews() {
  els.reviewList.innerHTML = "";
  const all = [...state.reviews, ...PRODUCTS.flatMap((p) => p.reviews || [])];
  all.slice(0, 9).forEach((r) => {
    const card = document.createElement("div");
    card.className = "review";
    card.innerHTML = `
      <div class="author">${r.author}</div>
      <div class="rating">★ ${r.rating}</div>
      <div class="text">${r.text}</div>
      <div class="date">${r.date}</div>
    `;
    els.reviewList.appendChild(card);
  });
}

function getCurrentPrice(product, fabricId = state.selectedFabric) {
  const delta =
    product.fabrics.find((f) => f.id === fabricId)?.priceDelta || 0;
  return product.price + delta;
}

function getCartTotal() {
  return state.cart.reduce((acc, item) => acc + item.price * item.qty, 0);
}

function applySort(list, sort) {
  const arr = [...list];
  if (sort === "price-asc") return arr.sort((a, b) => a.price - b.price);
  if (sort === "price-desc") return arr.sort((a, b) => b.price - a.price);
  if (sort === "new") return arr.sort((a, b) => (b.badge === "Новинка") - (a.badge === "Новинка"));
  return arr; // популярные — порядок как задан в данных
}

function formatPrice(num) {
  return `${(num || 0).toLocaleString("ru-RU")} ₽`;
}

function showQuote(text, type) {
  els.deliveryQuote.textContent = text;
  els.deliveryQuote.className = `quote ${type === "success" ? "success" : type === "error" ? "error" : ""}`;
}

function setCheckoutStatus(text, type) {
  els.checkoutStatus.textContent = text;
  els.checkoutStatus.className = `quote ${type === "success" ? "success" : type === "error" ? "error" : ""}`;
}

function setReviewStatus(text, type) {
  els.reviewStatus.textContent = text;
  els.reviewStatus.className = `quote ${type === "success" ? "success" : type === "error" ? "error" : ""}`;
}

function loadCart() {
  try {
    const raw = localStorage.getItem("boof-cart");
    return raw ? JSON.parse(raw) : [];
  } catch (e) {
    return [];
  }
}

function saveCart() {
  localStorage.setItem("boof-cart", JSON.stringify(state.cart));
}

function scrollToId(id) {
  const el = document.getElementById(id);
  if (el) el.scrollIntoView({ behavior: "smooth" });
}

function sleep(ms) {
  return new Promise((res) => setTimeout(res, ms));
}

async function mockDelivery(address) {
  await sleep(500);
  const weight = state.cart.reduce((acc, i) => acc + i.weight * i.qty, 0) || 60;
  const base = 1200;
  const variable = Math.min(7000, weight * 20);
  return { price: base + variable, eta: "1–3 дня", address };
}

async function mockPayment(payload) {
  await sleep(700);
  return { status: "paid", transactionId: "TEST-" + Math.random().toString(36).slice(2, 8), amount: payload.total };
}

async function mockCreateDelivery(address, items) {
  await sleep(500);
  return { id: Math.floor(Math.random() * 90000 + 10000), eta: "2–4 дня", tracking: "YD-" + Math.random().toString(36).slice(2, 8), address, items };
}

