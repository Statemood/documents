# Prometheus





## 配置文件

- global
  - 全局配置，其中scrape_interval表示抓取一次数据的间隔时间，evaluation_interval表示进行告警规则检测的间隔时间；
- alerting
  - 告警管理器（Alertmanager）的配置；

- rule_files
  - 告警规则有哪些；

- scrape_configs
  - 抓取监控信息的目标。一个job_name就是一个目标，其targets就是采集信息的IP和端口。这里默认监控了Prometheus自己，可以通过修改这里来修改Prometheus的监控端口。Prometheus的每个exporter都会是一个目标，它们可以上报不同的监控信息，比如机器状态，或者mysql性能等等，不同语言sdk也会是一个目标，它们会上报你自定义的业务监控信息。