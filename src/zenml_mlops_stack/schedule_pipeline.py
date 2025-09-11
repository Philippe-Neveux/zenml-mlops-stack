from zenml.config.schedule import Schedule
from zenml_mlops_stack.train import training_pipeline

# Create a schedule using a cron expression
schedule = Schedule(
    name="training_pipeline_schedule",
    cron_expression="*/10 * * * *"  # Runs every 10 minutes
)

# Attach the schedule to your pipeline
scheduled_pipeline = training_pipeline.with_options(schedule=schedule)


if __name__ == "__main__":
    # Execute the scheduled pipeline
    scheduled_pipeline()