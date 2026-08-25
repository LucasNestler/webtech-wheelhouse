# Architectural Decisions Record — Wheelhouse

### Decision 1: Customer Ownership vs. Bike History
* **Question**: Can a bike change owners over time, and if so, should the repair history remain attached to the bike or follow the customer?
* **Assumption Made**: We assume a **Bike** is an independent entity tied to a unique serial number, and it has a foreign key pointing to its current **Customer** (`Bike.customer_id`). Repair orders are linked directly to `Bike.id`, not `Customer.id`. This ensures that when a bike is resold or transferred, a lookup by serial number retrieves all historical work performed on that physical vehicle regardless of who owned it at the time.
* **Alternative & Impact**: If repair history were instead owned by the `Customer` record, we would link `RepairOrder` directly to `Customer.id`. If a customer sold their bike to a new owner, the second owner would lose access to previous service logs (such as past fork replacements), or we would have to implement complex record-copying logic to transfer repair order histories between customer accounts.

---

### Decision 2: Granularity of Status Tracking
* **Question**: Is repair progress tracked at the overall order level or per individual line item task?
* **Assumption Made**: We assume repair status (`status`) is managed strictly at the **`RepairOrder`** level (e.g., `Dropped Off`, `Awaiting Estimate Approval`, `In Progress`, `Ready for Pickup`, `Picked Up`). Mechanics mark the whole job as in-progress or ready, keeping workflow tracking simple for counter staff answering phone calls.
* **Alternative & Impact**: If individual line items required separate state tracking (e.g., "Wheel True completed, but Brake Bleed still pending"), we would move the `status` attribute from `RepairOrder` to `RepairLineItem`. This would require UI indicators for partial completion and additional mechanics' time logging, increasing system complexity without a clear requirement in the initial description.

---

### Decision 3: Annual Catalog Price Updates vs. Historical Invoices
* **Question**: How are yearly catalog price changes managed without affecting prior years' line items or breaking annual reporting?
* **Assumption Made**: We assume `ServiceCatalog` stores current active pricing alongside an `active_year` flag, while `RepairLineItem` explicitly snapshots the `charged_price` at the moment a service is added to an order. The catalog serves as a template, but historical billing records rely solely on `charged_price`.
* **Alternative & Impact**: If we instead maintained a historical lookup table for standard prices (versioned catalog prices by effective date range) and omitted `charged_price` on line items, every invoice calculation would require complex date-range queries. Furthermore, custom discounts granted to regular customers would either be impossible or require a separate "discounts" table.