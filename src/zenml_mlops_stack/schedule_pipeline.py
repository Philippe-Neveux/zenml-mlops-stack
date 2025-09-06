from zenml_mlops_stack.train import training_pipeline
from zenml.config.schedule import Schedule

# Create a schedule using a cron expression
schedule = Schedule(cron_expression="0 * * * *")  # Runs every hour

# Attach the schedule to your pipeline
scheduled_pipeline = training_pipeline.with_options(schedule=schedule)


if __name__ == "__main__":
    # Execute the scheduled pipeline
    scheduled_pipeline()