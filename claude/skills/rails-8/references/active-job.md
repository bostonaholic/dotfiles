# Active Job Reference

Active Job provides a framework for declaring background jobs and running them on various queuing backends.

## Creating Jobs

```bash
bin/rails generate job ProcessOrder
```

### Basic Job Structure

```ruby
# app/jobs/process_order_job.rb
class ProcessOrderJob < ApplicationJob
  queue_as :default

  def perform(order)
    order.process!
    OrderMailer.with(order: order).confirmation.deliver_later
  end
end
```

### ApplicationJob Base

```ruby
# app/jobs/application_job.rb
class ApplicationJob < ActiveJob::Base
  # Automatically retry failed jobs
  retry_on ActiveRecord::Deadlocked, wait: 5.seconds, attempts: 3
  retry_on Net::OpenTimeout, wait: :polynomially_longer, attempts: 10

  # Discard jobs that can't be fixed by retrying
  discard_on ActiveJob::DeserializationError

  # Set default queue
  queue_as :default
end
```

## Enqueueing Jobs

### Basic Enqueueing

```ruby
# Enqueue to run as soon as possible
ProcessOrderJob.perform_later(order)

# Enqueue with delay
ProcessOrderJob.set(wait: 10.minutes).perform_later(order)
ProcessOrderJob.set(wait_until: Date.tomorrow.noon).perform_later(order)

# Specify queue
ProcessOrderJob.set(queue: :urgent).perform_later(order)

# Combine options
ProcessOrderJob.set(
  wait: 1.hour,
  queue: :low_priority,
  priority: 10
).perform_later(order)

# Execute immediately (synchronous, for testing/debugging)
ProcessOrderJob.perform_now(order)
```

### Bulk Enqueueing

```ruby
# Enqueue multiple jobs efficiently
ActiveJob.perform_all_later(
  ProcessOrderJob.new(order1),
  ProcessOrderJob.new(order2),
  ProcessOrderJob.new(order3)
)
```

## Queue Configuration

### Queue Names

```ruby
class ProcessOrderJob < ApplicationJob
  queue_as :orders
end

class SendNewsletterJob < ApplicationJob
  queue_as :mailers
end

class GenerateReportJob < ApplicationJob
  queue_as :low_priority
end

# Dynamic queue based on arguments
class PriorityJob < ApplicationJob
  queue_as do
    if self.arguments.first.priority == "high"
      :urgent
    else
      :default
    end
  end
end
```

### Queue Adapter (Solid Queue - Rails 8 Default)

```ruby
# config/application.rb
config.active_job.queue_adapter = :solid_queue

# Or per-environment
# config/environments/production.rb
config.active_job.queue_adapter = :solid_queue

# config/environments/test.rb
config.active_job.queue_adapter = :test

# config/environments/development.rb
config.active_job.queue_adapter = :async  # In-process, no persistence
```

### Solid Queue Configuration

```yaml
# config/queue.yml
default: &default
  dispatchers:
    - polling_interval: 1
      batch_size: 500
  workers:
    - queues: "*"
      threads: 3
      processes: 1
      polling_interval: 0.1

production:
  <<: *default
  workers:
    - queues: [urgent, default]
      threads: 5
      processes: 2
    - queues: [low_priority]
      threads: 2
      processes: 1
```

## Callbacks

```ruby
class ProcessOrderJob < ApplicationJob
  # Enqueueing callbacks
  before_enqueue :log_enqueue
  after_enqueue :notify_enqueued
  around_enqueue :wrap_enqueue

  # Performing callbacks
  before_perform :setup
  after_perform :cleanup
  around_perform :with_logging

  def perform(order)
    order.process!
  end

  private

  def log_enqueue
    Rails.logger.info "Enqueueing ProcessOrderJob for order #{arguments.first.id}"
  end

  def notify_enqueued
    # Notify monitoring system
  end

  def wrap_enqueue
    Rails.logger.info "Starting enqueue"
    yield
    Rails.logger.info "Finished enqueue"
  end

  def setup
    @start_time = Time.current
  end

  def cleanup
    duration = Time.current - @start_time
    Rails.logger.info "Job completed in #{duration}s"
  end

  def with_logging
    Rails.logger.info "Starting job"
    yield
    Rails.logger.info "Finished job"
  rescue => e
    Rails.logger.error "Job failed: #{e.message}"
    raise
  end
end
```

## Error Handling

### Retry Configuration

```ruby
class ProcessOrderJob < ApplicationJob
  # Retry specific exceptions
  retry_on ActiveRecord::Deadlocked, wait: 5.seconds, attempts: 3

  # Exponential backoff
  retry_on Net::OpenTimeout, wait: :polynomially_longer, attempts: 10

  # Custom wait calculation
  retry_on Timeout::Error, wait: ->(executions) { executions * 2 }, attempts: 5

  # With jitter (randomization to prevent thundering herd)
  retry_on APIRateLimitError, wait: 30.seconds, attempts: 5, jitter: 0.30

  # Callback on each retry
  retry_on ServiceUnavailable, attempts: 3 do |job, error|
    ExceptionNotifier.notify(error, job: job)
  end

  def perform(order)
    ExternalService.process(order)
  end
end
```

### Discard Configuration

```ruby
class ProcessOrderJob < ApplicationJob
  # Discard job on specific exceptions
  discard_on ActiveJob::DeserializationError
  discard_on OrderCancelledError

  # With callback
  discard_on InvalidOrderError do |job, error|
    Rails.logger.warn "Discarding job: #{error.message}"
    ErrorTracker.track(error)
  end

  def perform(order)
    raise OrderCancelledError if order.cancelled?
    order.process!
  end
end
```

### Manual Error Handling

```ruby
class ProcessOrderJob < ApplicationJob
  rescue_from Exception do |exception|
    Rails.logger.error "Job failed: #{exception.message}"
    ErrorTracker.capture(exception)
    raise  # Re-raise to trigger retry
  end

  rescue_from SpecificError do |exception|
    # Handle without retrying
    Rails.logger.warn "Handled error: #{exception.message}"
  end

  def perform(order)
    order.process!
  end
end
```

## Job Arguments

### Supported Types

```ruby
class ExampleJob < ApplicationJob
  def perform(
    string,           # Basic types
    number,
    boolean,
    array,            # Arrays of basic types
    hash,             # Hashes with symbol keys
    record,           # ActiveRecord objects (serialized as GlobalID)
    time,             # Time, DateTime, Date
    duration,         # ActiveSupport::Duration
    range             # Ranges of basic types
  )
  end
end

# Calling
ExampleJob.perform_later(
  "text",
  42,
  true,
  [1, 2, 3],
  { key: "value" },
  User.find(1),
  Time.current,
  1.hour,
  1..10
)
```

### Custom Serializers

```ruby
# config/initializers/active_job_serializers.rb
class MoneySerializer < ActiveJob::Serializers::ObjectSerializer
  def serialize(money)
    super({ "amount" => money.amount, "currency" => money.currency })
  end

  def deserialize(hash)
    Money.new(hash["amount"], hash["currency"])
  end

  private

  def klass
    Money
  end
end

Rails.application.config.active_job.custom_serializers << MoneySerializer
```

## Transactional Integrity

```ruby
class ProcessOrderJob < ApplicationJob
  # Wait for transaction to commit before enqueueing
  # Prevents jobs from running against uncommitted data
  self.enqueue_after_transaction_commit = :always  # or :default, :never

  def perform(order)
    order.process!
  end
end

# In controller/service
Order.transaction do
  order = Order.create!(params)
  ProcessOrderJob.perform_later(order)  # Waits for commit
end
```

## Recurring Jobs (Solid Queue)

```ruby
# config/recurring.yml
production:
  cleanup_old_records:
    class: CleanupJob
    schedule: every day at 3am
    queue: maintenance

  send_daily_digest:
    class: DigestEmailJob
    schedule: every day at 9am
    queue: mailers

  sync_inventory:
    class: InventorySyncJob
    schedule: every 15 minutes
    queue: default
```

## Testing

### Test Helpers

```ruby
class ProcessOrderJobTest < ActiveJob::TestCase
  test "processes order" do
    order = orders(:pending)

    assert_enqueued_with(job: ProcessOrderJob, args: [order]) do
      ProcessOrderJob.perform_later(order)
    end
  end

  test "order is processed" do
    order = orders(:pending)

    perform_enqueued_jobs do
      ProcessOrderJob.perform_later(order)
    end

    order.reload
    assert_equal "processed", order.status
  end

  test "retries on network error" do
    order = orders(:pending)
    ExternalService.stub(:process, -> { raise Net::OpenTimeout }) do
      assert_enqueued_with(job: ProcessOrderJob) do
        ProcessOrderJob.perform_later(order)
      end
    end
  end
end
```

### Test Mode Configuration

```ruby
# test/test_helper.rb
class ActiveSupport::TestCase
  # Run jobs inline during tests
  include ActiveJob::TestHelper

  def perform_enqueued_jobs_inline
    ActiveJob::Base.queue_adapter = :inline
    yield
  ensure
    ActiveJob::Base.queue_adapter = :test
  end
end
```

### System Test Integration

```ruby
class OrderFlowTest < ApplicationSystemTestCase
  test "completing order triggers processing" do
    visit new_order_path
    fill_in "Product", with: "Widget"
    click_on "Place Order"

    perform_enqueued_jobs

    assert_text "Order processed"
  end
end
```

## Monitoring

### Job Instrumentation

```ruby
# config/initializers/active_job_logging.rb
ActiveSupport::Notifications.subscribe("perform.active_job") do |*args|
  event = ActiveSupport::Notifications::Event.new(*args)
  job = event.payload[:job]

  Rails.logger.info({
    job_class: job.class.name,
    job_id: job.job_id,
    queue: job.queue_name,
    duration: event.duration,
    arguments: job.arguments
  }.to_json)
end
```

### Mission Control (UI for Solid Queue)

```ruby
# Gemfile
gem "mission_control-jobs"

# config/routes.rb
mount MissionControl::Jobs::Engine, at: "/jobs"
```

## Best Practices

1. **Keep jobs small** - Single responsibility, easy to retry
2. **Make jobs idempotent** - Safe to run multiple times
3. **Use GlobalID** - Pass records, not IDs (handles deletion gracefully)
4. **Set appropriate queues** - Separate urgent from background work
5. **Configure retries thoughtfully** - Exponential backoff prevents overload
6. **Test job behavior** - Not just enqueueing
7. **Monitor queue depth** - Alert on growing backlogs
8. **Use transactions wisely** - `enqueue_after_transaction_commit` prevents race conditions
