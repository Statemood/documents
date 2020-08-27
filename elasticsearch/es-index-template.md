# Elasticsearch Index Template



```json
{
  "index": {
    "number_of_shards": "3",
    "number_of_replicas": "1",
    "routing": {
      "allocation": {
        "require": {
          "box_type": "hot"
        }
      }
    }
  }
}
```

