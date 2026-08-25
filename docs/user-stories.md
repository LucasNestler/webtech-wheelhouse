### Role: Counter Staff
* **US-01**: As a Counter Staff member, I want to record a customer's name and phone number on an intake record so that we can contact them about their repair status.
* **US-02**: As a Counter Staff member, I want to log the bike's make, model, and serial number during intake so that we distinguish between identical bike models and avoid returning the wrong bike.
* **US-03**: As a Counter Staff member, I want to take and attach photos of a bike upon arrival so that the shop has visual proof of its incoming condition and existing scratches.
* **US-04**: As a Counter Staff member, I want to search and view the current repair status of any bike on a central dashboard so that I can immediately answer phone inquiries without walking to the back workshop.

### Role: Mechanic
* **US-05**: As a Mechanic, I want to write detailed diagnostic paragraphs and notes for a repair order so that clear, readable findings are preserved for the team and customer.
* **US-06**: As a Mechanic, I want to add specific repair tasks from the standard service list to a repair order so that all work performed is accurately itemized.
* **US-07**: As a Mechanic, I want to view the past repair history of a bike by its serial number so that I know what work was previously performed regardless of who currently owns it.

### Role: Shop Owner
* **US-08**: As a Shop Owner, I want to set a promised return date when taking in a bike so that our team commits to clear turnaround times.
* **US-09**: As a Shop Owner, I want past invoices to lock in the prices charged at the time of repair so that annual price list updates do not retroactively alter historical financial records.
* **US-10**: As a Shop Owner, I want to see visual indicators for active repairs that have passed their promised delivery date so that I can resolve overdue jobs before customers call.

### Role: Public / Customer
* **US-11**: As a Public Customer, I want to view the standard repair service list and current prices on the shop website so that I can check service costs without calling.

### US-12 
> **US-12**: As a Counter Staff member, I want to manage a complete customer repair visit from intake to final pickup so that shop operations flow smoothly.

* **US-12a (Intake & Queueing)**: As a Counter Staff member, I want to log a bike intake with customer details, serial number, photos, and a promised date so that the job enters the active workshop queue.
* **US-12b (Estimate Authorization)**: As a Counter Staff member, I want to record a customer’s approval or rejection of a repair estimate so that mechanics know whether to proceed with work or prepare the bike for pickup.
* **US-12c (Checkout & Pickup)**: As a Counter Staff member, I want to mark a repair order as picked up and finalized so that the bike is officially checked out of the shop.

---

## 3. Acceptance Criteria

### US-04: Central Status Dashboard (Counter Staff)
* **AC-01**: Given a customer calls to check on a repair, when Counter Staff searches by customer name or bike serial number, then matching repair orders display their current state (e.g., `In Progress`, `Completed`).
* **AC-02**: Given an active repair order, when selected from the dashboard, then assigned mechanic notes and promised delivery dates are visible.
* **AC-03 (Empty State)**: Given there are no active repairs currently in the workshop queue, when Counter Staff views the dashboard, then a clear message stating *"No active repairs in workshop"* is displayed instead of a blank region.

### US-02: Bike Identification at Intake (Counter Staff)
* **AC-01**: Given a new intake form, when submitting without filling in `Make`, `Model`, or `Serial Number`, then validation errors prevent saving and highlight the missing fields.
* **AC-02**: Given a serial number entered at intake, when that serial number exists in system history, then previous repair records linked to that serial number are attached to the new order context.
* **AC-03**: Given two bikes of identical make and model, when entered into the system, then unique system record IDs and serial numbers ensure their repair histories remain completely independent.

### US-06: Adding Service Line Items (Mechanic)
* **AC-01**: Given an active repair order, when a mechanic adds a line item, then available services populate from the master catalog.
* **AC-02**: Given a custom or discounted job rate, when a mechanic manual price adjustment is entered, then the line item updates to the custom price for that specific repair instance without modifying the master catalog price.
* **AC-03**: Given service items added to a repair order, when saved, then total job cost recalculates immediately.

### US-10: Overdue Repair Alerts (Shop Owner)
* **AC-01**: Given a repair order with a `promised_date` earlier than today's date and a status other than `Completed` or `Picked Up`, when viewed on the dashboard, then an overdue alert flag is displayed.
* **AC-02**: Given a repair order completed before or on the `promised_date`, when viewed on the screen, then no overdue alert flag is displayed.
* **AC-03**: Given the active repairs list on the dashboard, when sorted by urgency, then overdue repair orders appear prioritized at the top of the view.