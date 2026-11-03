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

### Decision 4: The Default Role of an Account
* **Question**: Sign-up is public and cannot choose a role, so every new account starts with the default. Which of `owner`, `mechanic` and `counter` has the fewest permissions?
* **Assumption Made**: The default is **`mechanic`**. A mechanic needs the job on the bench and little else. The person at the counter deals with customers, their phone numbers, estimates and money, and the owner answers for all of it. Customers do not have accounts, so there is no `client` role.
* **Alternative & Impact**: If the default were `counter`, a new account would start with the role closest to customers' personal data and to the money. The role does not restrict any page yet: until it does, anyone who signs up can open every page that requires a session, whatever the default is.

### Decision 5: Intake Photos and the Session
* **Question**: Every page requires a session. Do the files of the intake photos require one as well?
* **Assumption Made**: No. Active Storage serves them from its own controllers, through long signed URLs that nobody can guess. A visitor can only reach a photo with a URL that was first shown to someone signed in.
* **Alternative & Impact**: Requiring a session for the files would mean replacing the routes of Active Storage, for a risk that only appears if someone shares a URL.
