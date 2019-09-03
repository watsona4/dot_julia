```@meta
CurrentModule = REDCap
```
# Deletion

Records, Files, Arms, and Events may be deleted from a project via API call.

## Records

```@docs
delete_records(config::REDCap.Config, records::Array; arm::Integer=0)
```
#### Notes:

An array of `record_id` names is passed, and if they exist, they will be deleted.

```julia
#For non-longitudinal projects
delete_records(config, ["1","2","25"])

delete_records(config, ["1","2","25"], arm="1")
```
The number of records deleted will be returned. If a record is specified that does not exist, REDCap will throw an error (It will <b>NOT</b> delete the valid ids).

## Files

```@docs
delete_file(config::REDCap.Config, record::String, field::String, event::String; repeat_instance::Integer=1, returnFormat::String="json") 
```
#### Notes:

The location of the file must be specified by passing the record name, the field containing the file, and the event.

```julia
delete_file(config, "2", "file_upload", "event")
```

## Arms

```@docs
delete_arms(config::REDCap.Config, arms::Array) 
```

```julia
delete_arms(config, ["1"])
```

## Events

```@docs
delete_events(config::REDCap.Config, events::Array)
```

```julia
delete_events(config, ["event_1_arm_1"])
```