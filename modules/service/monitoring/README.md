# Service Monitoring

## Overview  
The `service_monitoring` intent adds monitoring capabilities to Kubernetes-based services deployed on multiple cloud platforms such as AWS, Kubernetes, Azure, and GCP. It enables configuration of service metrics and alerting rules to monitor application health and resource usage effectively.

## Configurability  

### Metrics Configuration  
Users can configure metrics exposure details:  
- **path:** The HTTP path exposing the metrics (for example, `/metrics`).  
- **port_name:** The service port name exposing metrics.  
- **scrape_interval:** The frequency at which metrics should be scraped, with supported duration formats like `72h`, `3.5m`, `1.2s`, `500ms`, etc.

### Alerts Configuration  
Individual alerts can be enabled or disabled and configured with trigger intervals and severity levels. Thresholds apply where relevant.

| Alert Name                  | Description                             | Configurable Fields                        |
|----------------------------|---------------------------------------|--------------------------------------------|
| Pod Pending Alert           | Detects pods stuck in Pending state   | disabled, interval, severity               |
| Pod Crashlooping Alert      | Detects CrashLoopBackOff containers   | disabled, interval, severity               |
| Invalid Image Name Alert    | Detects invalid image name errors     | disabled, interval, severity               |
| Pod Waiting Alert           | Detects containers in waiting state   | disabled, interval, severity               |
| CPU Throttling Alert        | CPU throttling exceeds threshold      | disabled, interval, severity, threshold   |
| High Memory Utilization Alert | Memory usage exceeds threshold      | disabled, interval, severity, threshold   |
| Pod Not Ready Alert         | Pods not reaching Ready state          | disabled, interval, severity               |
| Pod Evicted Alert           | Detects evicted pods                  | disabled, interval, severity               |
| Failed HTTP Requests Alert  | High failure rate of HTTP requests    | disabled, interval, severity, threshold   |
| Ingress Endpoints Alert     | Ingress endpoints not active           | disabled, interval, severity               |
| Service VPA CPU Alert       | Vertical Pod Autoscaler CPU alert      | disabled, interval, severity, threshold   |
| Service VPA Memory Alert    | Vertical Pod Autoscaler Memory alert   | disabled, interval, severity, threshold   |

## Usage  
The intent supports detailed configuration of metrics paths, scrape intervals, and fine-tuned alerting rules to ensure proactive monitoring and rapid response to service anomalies or resource constraints.
