{{/*
Expand the name of the chart.
*/}}
{{- define "app-chart.name" -}}
{{- default .Chart.Name .Values.metadata.name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "app-chart.fullname" -}}
{{- if .Values.metadata.name }}
{{- .Values.metadata.name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.metadata.name }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Add metadata to all the kubernetes objects that will inherit from the module chart
*/}}
{{- define "app-chart.metadataLabels" -}}
{{ with .Values.metadata.labels }}
{{- toYaml . -}}
{{ end }}
{{- if .Values.metadata.labels.resourceName }}
resourceName: {{ .Values.metadata.labels.resourceName }}
{{- else }}
resourceName: {{ include "app-chart.fullname" . }}
{{- end }}
resourceType: service
{{ include "app-chart.selectorLabels" . }}
{{- end -}}

{{/*
Add metadata to all the kubernetes objects that will inherit from the module chart
*/}}
{{- define "app-chart.metadataAnnotations" -}}
{{ with .Values.metadata.annotations }}
{{- toYaml . -}}
{{ end }}
{{- end -}}

{{/*
Add imagepullsecrets to all the kubernetes objects that will inherit from the module chart
*/}}
{{- define "app-chart.imagePullSecrets" -}}
{{- range $sec := .Values.advanced.common.app_chart.values.image_pull_secrets }}
- name: {{ $sec.name }}
{{- end }}
{{- end -}}

{{/*
Inject env variables to the respecitve containers
*/}}
{{- define "app-chart.env" -}}
{{- $name := .Values.metadata.name -}}
{{- $allowDots := default false .Values.advanced.common.app_chart.values.allow_dots_in_env -}}
{{- range $k, $v := .Values.spec.env }}
{{- if and (regexMatch "[.]" $k) (not $allowDots) }}
{{- $K := $k | upper | replace "." "_" }}
- name: {{ $K }}
  valueFrom:
    secretKeyRef:
      name: {{ $name }}-secret
      key: {{ $K }}
{{- else }}
- name: {{ $k }}
  valueFrom:
    secretKeyRef:
      name: {{ $name }}-secret
      key: {{ $k }}
{{- end }}
{{- end }}
- name: POD_IP
  valueFrom:
    fieldRef:
      fieldPath: status.podIP
- name: POD_CPU_REQUEST
  valueFrom:
    resourceFieldRef:
      containerName: {{ include "app-chart.fullname" . }}
      resource: requests.cpu
- name: POD_CPU_LIMIT
  valueFrom:
    resourceFieldRef:
      containerName: {{ include "app-chart.fullname" . }}
      resource: limits.cpu
- name: POD_MEM_REQUEST
  valueFrom:
    resourceFieldRef:
      containerName: {{ include "app-chart.fullname" . }}
      resource: requests.memory
- name: POD_MEM_LIMIT
  valueFrom:
    resourceFieldRef:
      containerName: {{ include "app-chart.fullname" . }}
      resource: limits.memory
{{- if and ( hasKey .Values.advanced.common.app_chart.values  "additional_k8s_env") (gt (len .Values.advanced.common.app_chart.values.additional_k8s_env) 0) }}
{{ toYaml .Values.advanced.common.app_chart.values.additional_k8s_env }}
{{- end }}
{{- end -}}

{{/*
Inject envFrom variables to the respecitve containers
*/}}
{{- define "app-chart.envFrom" -}}
{{- if and ( hasKey .Values.advanced.common.app_chart.values  "additional_k8s_env_from") (gt (len .Values.advanced.common.app_chart.values.additional_k8s_env_from) 0) }}
envFrom:
{{ toYaml .Values.advanced.common.app_chart.values.additional_k8s_env_from }}
{{- end }}
{{- end -}}

{{/*
configure resources for objects
*/}}
{{- define "app-chart.resources" -}}
{{- if hasKey .Values.spec.runtime "size" }}
limits:
{{- if hasKey .Values.spec.runtime.size "cpu_limit" }}
  cpu: {{ .Values.spec.runtime.size.cpu_limit }}
{{- else }}
  cpu: {{ .Values.spec.runtime.size.cpu }}
{{- end }}
{{- if hasKey .Values.spec.runtime.size "memory_limit" }}
  memory: {{ .Values.spec.runtime.size.memory_limit }}
{{- else }}
  memory: {{ .Values.spec.runtime.size.memory }}
{{- end }}
requests:
  cpu: {{ .Values.spec.runtime.size.cpu }}
  memory: {{ .Values.spec.runtime.size.memory }}
{{- else }}
limits:
  cpu: 1000m
  memory: 1000Mi
requests:
  cpu: 1000m
  memory: 1000Mi
{{- end }}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "app-chart.ports" -}}
{{- range $k, $v := .Values.spec.runtime.ports }}
{{- with . }}
- containerPort: {{ .port }}
  name: {{ $k | lower | replace "_" "-" }}
{{- end }}
{{- end }}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "app-chart.selectorLabels" -}}
app.kubernetes.io/name: {{ include "app-chart.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app: {{ include "app-chart.name" . }}
{{- end -}}

{{/*
command
*/}}
{{- define "app-chart.command" -}}
command:
{{- range $command := .Values.spec.runtime.command }}
- {{ $command | quote }}
{{- end }}
{{- end -}}

{{/*
args
*/}}
{{- define "app-chart.args" -}}
args:
{{- range $args := .Values.spec.runtime.args }}
- {{ $args | quote }}
{{- end }}
{{- end -}}

{{/*
Liveness and Readiness Check
*/}}
{{- define "app-chart.liveness-readiness-check" -}}
{{- if or (hasKey .Values.spec.runtime.health_checks "port") (hasKey .Values.spec.runtime.health_checks "liveness_port") (hasKey .Values.spec.runtime.health_checks "liveness_exec_command") }}
livenessProbe:
  failureThreshold: {{ default 10 .Values.spec.runtime.health_checks.liveness_failure_threshold }}
  initialDelaySeconds: {{ default .Values.spec.runtime.health_checks.start_up_time .Values.spec.runtime.health_checks.liveness_start_up_time | default 10 }}
  periodSeconds: {{ default .Values.spec.runtime.health_checks.period .Values.spec.runtime.health_checks.liveness_period | default 10 }}
  successThreshold: {{ default 1 .Values.spec.runtime.health_checks.liveness_success_threshold }}
  timeoutSeconds: {{ default .Values.spec.runtime.health_checks.timeout .Values.spec.runtime.health_checks.liveness_timeout | default 10 }}
{{- if or (hasKey .Values.spec.runtime.health_checks "liveness_url") (hasKey .Values.spec.runtime.health_checks "liveness_headers") }}
  httpGet:
    path: {{ .Values.spec.runtime.health_checks.liveness_url }}
    port: {{ default .Values.spec.runtime.health_checks.port .Values.spec.runtime.health_checks.liveness_port }}
{{- if and (hasKey .Values.spec.runtime.health_checks "liveness_headers") (gt (len .Values.spec.runtime.health_checks.liveness_headers) 0) }}
    httpHeaders:
    {{- range $header := .Values.spec.runtime.health_checks.liveness_headers }}
      {{- range $key, $value := $header }}
      - name: {{ $key }}
        value: {{ $value }}
      {{- end }}
    {{- end }}
{{- end }}
{{- else if (hasKey .Values.spec.runtime.health_checks "liveness_exec_command") }}
  exec:
    command:
    {{- range .Values.spec.runtime.health_checks.liveness_exec_command }}
    - {{ . }}
    {{- end }}
{{- else }}
  tcpSocket:
    port: {{ default .Values.spec.runtime.health_checks.port .Values.spec.runtime.health_checks.liveness_port }}
{{- end }}
{{- end }}
{{- if or (hasKey .Values.spec.runtime.health_checks "port") (hasKey .Values.spec.runtime.health_checks "readiness_port") (hasKey .Values.spec.runtime.health_checks "readiness_exec_command") }}
readinessProbe:
  failureThreshold: {{ default 10 .Values.spec.runtime.health_checks.readiness_failure_threshold }}
  initialDelaySeconds: {{ default .Values.spec.runtime.health_checks.start_up_time .Values.spec.runtime.health_checks.readiness_start_up_time | default 10 }}
  periodSeconds: {{ default .Values.spec.runtime.health_checks.period .Values.spec.runtime.health_checks.readiness_period | default 10 }}
  successThreshold: {{ default 1 .Values.spec.runtime.health_checks.readiness_success_threshold }}
  timeoutSeconds: {{ default .Values.spec.runtime.health_checks.timeout  .Values.spec.runtime.health_checks.readiness_timeout | default 10 }}
{{- if or (hasKey .Values.spec.runtime.health_checks "readiness_url") (hasKey .Values.spec.runtime.health_checks "readiness_headers") }}
  httpGet:
    path: {{ .Values.spec.runtime.health_checks.readiness_url }}
    port: {{ default .Values.spec.runtime.health_checks.port .Values.spec.runtime.health_checks.readiness_port }}
{{- if and (hasKey .Values.spec.runtime.health_checks "readiness_headers") (gt (len .Values.spec.runtime.health_checks.readiness_headers) 0) }}
    httpHeaders:
    {{- range $key, $header := .Values.spec.runtime.health_checks.readiness_headers }}
      {{- range $subkey, $subvalue := $header }}
      - name: {{ $key }}
        value: {{ $subvalue }}
      {{- end }}
    {{- end }}
{{- end }}
{{- else if (hasKey .Values.spec.runtime.health_checks "readiness_exec_command") }}
  exec:
    command:
    {{- range .Values.spec.runtime.health_checks.readiness_exec_command }}
    - {{ . }}
    {{- end }}
{{- else }}
  tcpSocket:
    port: {{ default .Values.spec.runtime.health_checks.port .Values.spec.runtime.health_checks.readiness_port }}
{{- end }}
{{- end -}}
{{- end -}}
{{/*
Mount configs in volumes for all type of kubernetes objects
*/}}
{{- define "app-chart.configsVolume" }}
{{ range $k, $v := .Values.spec.runtime.volumes.config_maps }}
- name: {{ $k | quote }}
  configMap:
    name: {{ $v.name | quote }}
{{- end -}}
{{- end }}

{{/*
Mount secrets in volumes for all type of kubernetes objects
*/}}
{{- define "app-chart.secretsVolume" -}}
{{- range $k, $v := .Values.spec.runtime.volumes.secrets }}
- name: {{ $k | quote }}
  secret:
    secretName: {{ $v.name | quote }}
{{- end }}
{{- end }}

{{- define "app-chart.Affinity" -}}
affinity:
{{- end }}
{{- define "app-chart.nodeAffinity" -}}
nodeAffinity:
{{- end }}
{{- define "app-chart.nodeAntiAffinity" -}}
nodeAntiAffinity:
{{- end }}
{{- define "app-chart.podAffinity" -}}
podAffinity:
{{- end }}
{{- define "app-chart.podAntiAffinity" -}}
podAntiAffinity:
{{- end }}

{{/*
Mount configs in volumes for all type of kubernetes objects
*/}}
{{- define "app-chart.configsVolumeMounts" -}}
{{- range $k, $v := .Values.spec.runtime.volumes.config_maps }}
- name: {{ $k| quote }}
  mountPath: {{ $v.mount_path | quote }}
  {{- if $v.sub_path }}
  subPath: {{ $v.sub_path | quote }}
  {{- end }}
{{- end }}
{{- end }}

{{/*
Mount secrets in volumes for all type of kubernetes objects
*/}}
{{- define "app-chart.secretsVolumeMounts" -}}
{{- range $k, $v := .Values.spec.runtime.volumes.secrets }}
- name: {{ $k| quote }}
  mountPath: {{ $v.mount_path | quote }}
  {{- if $v.sub_path }}
  subPath: {{ $v.sub_path | quote }}
  {{- end }}
{{- end }}
{{- end }}


{{/*
Pod topology for distributing pods across nodes
*/}}
{{- define "app-chart.pod_distribution" -}}
{{- $required := .Values.advanced.common.app_chart.values.pod_distribution }}
{{- $name := .Values.metadata.name }}
{{- if $required }}
topologySpreadConstraints:
{{- range $index, $topology := $required }}
- maxSkew: {{ $topology.max_skew }}
  whenUnsatisfiable: {{ $topology.when_unsatisfiable }}
  topologyKey: {{ $topology.topology_key | quote }}
  labelSelector:
    matchLabels:
      app: {{ $name }}
  matchLabelKeys:
    - pod-template-hash
  {{- with $topology.node_taints_policy }}
  nodeTaintsPolicy: {{ $topology.node_taints_policy | quote }}
  {{- end }}
  {{- with $topology.node_affinity_policy }}
  nodeAffinityPolicy: {{ $topology.node_affinity_policy | quote }}
  {{- end }}
  {{- end }}
{{- end }}
{{- end -}}

# POD affinity and anti affinity in advanced is on hold
{{/*
Pod anti-affinity required user specified :tick
*/}}
{{- define "app-chart.podAntiAffinityRequired" -}}
{{- $required := .Values.advanced.common.app_chart.values.pod.anti_affinity.required }}
{{- if $required }}
  requiredDuringSchedulingIgnoredDuringExecution:
  {{- range $index, $node := $required }}
  - labelSelector:
      matchExpressions:
      - key: {{ $node.key }}
        operator: {{ $node.operator }}
        values:
      {{- range $value := $node.values }}
        - {{ $value }}
      {{- end }}
    topologyKey: {{ $node.topology_key | quote }}
    # weight: {{ $node.weight | default 1 }}
    {{- end }}
{{- end }}
{{- end -}}

{{/*
Pod anti-affinity preferred user specified :tick
*/}}
{{- define "app-chart.podAntiAffinityPreferred" -}}
{{- $preferred := .Values.advanced.common.app_chart.values.pod.anti_affinity.preferred }}
{{- if $preferred }}
  preferredDuringSchedulingIgnoredDuringExecution:
  {{- range $index, $node := $preferred }}
  - weight: {{ $node.weight | default 1 }}
    podAffinityTerm:
      labelSelector:
        matchExpressions:
        - key: {{ $node.key }}
          operator: {{ $node.operator }}
          values:
        {{- range $value := $node.values }}
          - {{ $value }}
        {{- end }}
      topologyKey: {{ $node.topology_key | quote }}
    {{- end }}
{{- end }}
{{- end -}}


{{/*
Pod affinity required user specified :tick
*/}}
{{- define "app-chart.podAffinityRequired" -}}
{{- $required := .Values.advanced.common.app_chart.values.pod.affinity.required }}
{{- if $required }}
  requiredDuringSchedulingIgnoredDuringExecution:
  {{- range $index, $node := $required }}
  - labelSelector:
      matchExpressions:
      - key: {{ $node.key }}
        operator: {{ $node.operator }}
        values:
      {{- range $value := $node.values }}
        - {{ $value }}
      {{- end }}
    topologyKey: {{ $node.topology_key | quote }}
    # weight: {{ $node.weight | default 1 }}
    {{- end }}
{{- end }}
{{- end -}}

{{/*
Pod affinity preferred user specified :tick
*/}}
{{- define "app-chart.podAffinityPreferred" -}}
{{- $preferred := .Values.advanced.common.app_chart.values.pod.affinity.preferred }}
{{- if $preferred }}
  preferredDuringSchedulingIgnoredDuringExecution:
  {{- range $index, $node := $preferred }}
  - weight: {{ $node.weight | default 1 }}
    podAffinityTerm:
      labelSelector:
        matchExpressions:
        - key: {{ $node.key }}
          operator: {{ $node.operator }}
          values:
        {{- range $value := $node.values }}
          - {{ $value }}
        {{- end }}
      topologyKey: {{ $node.topology_key | quote }}
    {{- end }}
{{- end }}
{{- end -}}


{{/*
Node affinity for preferred :tick
*/}}
{{- define "app-chart.nodeAffinityPreferred" -}}
{{- $preferred := .Values.advanced.common.app_chart.values.node.affinity.preferred }}
{{- if $preferred }}
  preferredDuringSchedulingIgnoredDuringExecution:
  {{- range $index, $node := $preferred }}
  - weight: {{ $node.weight | default 1 }}
    preference:
      matchExpressions:
      - key: {{ $node.key }}
        operator: {{ $node.operator }}
        values:
        {{- range $value := $node.values }}
        - {{ $value }}
        {{- end }}
  {{- end }}
{{- end }}
{{- end -}}

{{/*
Node affinity for required  :tick
*/}}
{{- define "app-chart.nodeAffinityRequired" -}}
{{- $required := .Values.advanced.common.app_chart.values.node.affinity.required }}
{{- if $required }}
  requiredDuringSchedulingIgnoredDuringExecution:
    # weight: {{ $required.weight | default 1 }}
    nodeSelectorTerms:
    {{- range $index, $node := $required }}
    - matchExpressions:
      - key: {{ $node.key }}
        operator: {{ $node.operator }}
        values:
        {{- range $value := $node.values }}
        - {{ $value }}
        {{- end }}
    {{- end }}
{{- end }}
{{- end -}}

{{/*
Add toleration to all the kubernetes objects that will inherit from the module chart
*/}}
{{- define "app-chart.tolerations" -}}
{{- $tolerations := .Values.advanced.common.app_chart.values.tolerations }}
{{- if $tolerations }}
tolerations:
{{- range $key, $value := $tolerations }}
- key: {{ $value.key | quote }}
  operator: {{ $value.operator | quote }}
  value: {{ $value.value | quote }}
  effect: {{ $value.effect | quote }}
{{- end }}
{{- end }}
{{- end -}}

{{/*
Add security context to the pods
*/}}
{{- define "app-chart.securityContext" -}}
{{- $securitycontext := .Values.advanced.common.app_chart.values.security_context }}
{{- if $securitycontext }}
securityContext:
{{- if hasKey $securitycontext "fsgroup" }}
  fsGroup: {{ $securitycontext.fsgroup }}
{{- end -}}
{{- if hasKey $securitycontext "run_as_user" }}
  runAsUser: {{ $securitycontext.run_as_user }}
{{- end -}}
{{- if hasKey $securitycontext "run_as_group" }}
  runAsGroup: {{ $securitycontext.run_as_group }}
{{- end -}}
{{- if hasKey $securitycontext "fs_group_change_policy" }}
  fsGroupChangePolicy: {{ $securitycontext.fs_group_change_policy }}
{{- end -}}
{{- if hasKey $securitycontext "run_as_non_root" }}
  runAsNonRoot: {{ $securitycontext.run_as_non_root }}
{{- end -}}
{{- if hasKey $securitycontext "linux_options" }}
  seLinuxOptions: 
{{ toYaml $securitycontext.linux_options | indent 4 }}
{{- end -}}
{{- if hasKey $securitycontext "comp_profile" }}
  seccompProfile: 
{{ toYaml $securitycontext.comp_profile | indent 4 }}
{{- end -}}
{{- if hasKey $securitycontext "supplemental_groups" }}
  supplementalGroups: 
    {{- toYaml $securitycontext.supplemental_groups | nindent 2 }}
{{- end -}}
{{- if hasKey $securitycontext "sysctls" }}
  sysctls: 
    {{- toYaml $securitycontext.sysctls | nindent 2 }}
{{- end -}}
{{- if hasKey $securitycontext "windows_options" }}
  windowsOptions: 
    {{- toYaml $securitycontext.windows_options | nindent 2}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Add sidecars to all the kubernetes objects that will inherit from the module chart
*/}}
{{- define "app-chart.sidecars" -}}
{{- range $k, $v := .Values.advanced.common.app_chart.values.sidecars }}
- name: {{ $k }}
  image: {{ $v.image }}
  {{- if or (hasKey $v "env") ( hasKey $v  "additional_k8s_env") }}
  env:
  {{- range $envName, $envValue := $v.env }}
  - name: {{ $envName | quote }}
    value: {{ $envValue | quote }}
  {{- end }}
  {{- if and ( hasKey $v  "additional_k8s_env") (gt (len $v.additional_k8s_env) 0) }}
  {{- toYaml $v.additional_k8s_env | nindent 2 }}
  {{- end }}
  {{- end }}
  {{- if and ( hasKey $v  "additional_k8s_env_from") (gt (len $v.additional_k8s_env_from) 0) }}
  envFrom:
  {{- toYaml $v.additional_k8s_env_from | nindent 2 }}
  {{- end }}
  imagePullPolicy: {{ $v.pull_policy | default "IfNotPresent" }}
{{- if and ( hasKey $v "runtime") (gt (len $v.runtime) 0) }}
{{- if  hasKey $v.runtime  "command" }}
{{- if gt (len $v.runtime.command) 0 }}
  command:
    {{- toYaml $v.runtime.command | nindent 2 }}
{{- end }}
{{- end }}
{{- if  hasKey $v.runtime  "args" }}
{{- if gt (len $v.runtime.args) 0 }}
  args:
    {{- toYaml $v.runtime.args | nindent 2 }}
{{- end }}
{{- end }}
{{- if ( hasKey $v.runtime "health_checks") }}
  livenessProbe:
    failureThreshold: {{ default 10 $v.runtime.health_checks.liveness_failure_threshold }}
    initialDelaySeconds: {{ default 10 $v.runtime.health_checks.start_up_time }}
    periodSeconds: {{ default 10 $v.runtime.health_checks.period }}
    successThreshold: {{ default 1 $v.runtime.health_checks.liveness_success_threshold }}
    timeoutSeconds: {{  $v.runtime.health_checks.timeout }}
  {{- if (hasKey $v.runtime.health_checks "liveness_url") }}
    httpGet:
      path: {{ $v.runtime.health_checks.liveness_url }}
      port: {{ $v.runtime.health_checks.port }}
  {{- else if (hasKey $v.runtime.health_checks "liveness_exec_command") }}
    exec:
      command:
      {{- range $v.runtime.health_checks.liveness_exec_command }}
      - {{ . }}
      {{- end }}
  {{- else }}
    tcpSocket:
      port: {{ $v.runtime.health_checks.port }}
  {{- end }}
  readinessProbe:
    failureThreshold: {{ default 10 $v.runtime.health_checks.readiness_failure_threshold }}
    initialDelaySeconds: {{ default 10 $v.runtime.health_checks.start_up_time }}
    periodSeconds: {{ default 10 $v.runtime.health_checks.period }}
    successThreshold: {{ default 1 $v.runtime.health_checks.readiness_success_threshold }}
    timeoutSeconds: {{  $v.runtime.health_checks.timeout }}
  {{- if (hasKey $v.runtime.health_checks "readiness_url") }}
    httpGet:
      path: {{ $v.runtime.health_checks.readiness_url }}
      port: {{ $v.runtime.health_checks.port }}
  {{- else if (hasKey $v.runtime.health_checks "readiness_exec_command") }}
    exec:
      command:
      {{- range $v.runtime.health_checks.readiness_exec_command }}
      - {{ . }}
      {{- end }}
  {{- else }}
    tcpSocket:
      port: {{ $v.runtime.health_checks.port }}
  {{- end }}
{{- end }}
{{- if  hasKey $v.runtime  "ports" }}
{{- if gt (len $v.runtime.ports) 0 }}
  ports:
  {{- range $a, $b := $v.runtime.ports }}
  - containerPort: {{ $b.port }}
    name: {{ $a | lower | replace "_" "-" }}
  {{- end }}
{{- end }}
{{- end }}
{{- if and ( hasKey $v.runtime  "volumes") (gt (len $v.runtime.volumes) 0) }}
  volumeMounts:
{{- if and ( hasKey $v.runtime.volumes  "config_maps") (gt (len $v.runtime.volumes.config_maps) 0) }}
  {{- range $a, $b := $v.runtime.volumes.config_maps }}
  - name: {{ $a| quote }}
    mountPath: {{ $b.mount_path | quote }}
    {{- if $b.sub_path }}
    subPath: {{ $b.sub_path | quote }}
    {{- end }}
  {{- end }}
{{- end }}
{{- if and ( hasKey $v.runtime.volumes  "host_path") (gt (len $v.runtime.volumes.host_path) 0) }}
  {{- range $a, $b := $v.runtime.volumes.host_path }}
  - name: {{ $a| quote }}
    mountPath: {{ $b.mount_path | quote }}
    {{- if $b.sub_path }}
    subPath: {{ $b.sub_path | quote }}
    {{- end }}
  {{- end }}
{{- end }}
{{- if and ( hasKey  $v.runtime.volumes  "secrets") (gt (len  $v.runtime.volumes.secrets) 0) }}
  {{- range $a, $b := $v.runtime.volumes.secrets }}
  - name: {{ $a| quote }}
    mountPath: {{ $b.mount_path | quote }}
    {{- if $b.sub_path }}
    subPath: {{ $b.sub_path | quote }}
    {{- end }}
  {{- end }}
{{- end }}
{{- if and ( hasKey  $v.runtime.volumes  "pvc") (gt (len  $v.runtime.volumes.pvc) 0) }}
  {{- range $a, $b := $v.runtime.volumes.pvc }}
  - name: {{ $a| quote }}
    mountPath: {{ $b.mount_path | quote }}
    {{- if $b.sub_path }}
    subPath: {{ $b.sub_path | quote }}
    {{- end }}
  {{- end }}
{{- end }}
{{- if and ( hasKey  $v.runtime.volumes  "additional_volume_mounts") (gt (len  $v.runtime.volumes.additional_volume_mounts) 0) }}
{{- toYaml $v.runtime.volumes.additional_volume_mounts | nindent 2 }}
{{- end }}
{{- end }}
  resources:
  {{- if hasKey $v.runtime "size" }}
    limits:
    {{- if hasKey $v.runtime.size "cpu_limit" }}
      cpu: {{ $v.runtime.size.cpu_limit }}
    {{- else }}
      cpu: {{ $v.runtime.size.cpu }}
    {{- end }}
    {{- if hasKey $v.runtime.size "memory_limit" }}
      memory: {{ $v.runtime.size.memory_limit }}
    {{- else }}
      memory: {{ $v.runtime.size.memory }}
    {{- end }}
    requests:
      cpu: {{ $v.runtime.size.cpu }}
      memory: {{ $v.runtime.size.memory }}
    {{- end }}
  {{- end }}
{{- end }}
{{- end }}

{{/*
Mount PVC in volumes for all type of kubernetes objects
*/}}
{{- define "app-chart.pvcVolume" -}}
{{- range $k, $v := .Values.spec.runtime.volumes.pvc }}
- name: {{ $k | quote }}
  persistentVolumeClaim:
    claimName: {{ $v.claim_name | quote }}
{{- end }}
{{- end -}}

{{/*
Mount PVC in Volume Mount for all type of kubernetes objects
*/}}
{{- define "app-chart.pvcVolumeMounts" -}}
{{- range $k, $v := .Values.spec.runtime.volumes.pvc }}
- name: {{ $k | quote }}
  mountPath: {{ $v.mount_path | quote }}
  {{- if $v.sub_path }}
  subPath: {{ $v.sub_path | quote }}
  {{- end }}
{{- end }}
{{- end -}}

{{/*
Mount HostPath in volumes for all type of kubernetes objects
*/}}
{{- define "app-chart.hostPathVolume" -}}
{{- range $k, $v := .Values.spec.runtime.volumes.host_path }}
- name: {{ $k | quote }}
  hostPath:
    path: {{ ($v.host_path | default $v.mount_path) | quote }}
    {{- if and ( hasKey $v "type") (gt (len $v.type) 0) }}
    type: {{ $v.type | quote }}
    {{- end }}
{{- end }}
{{- end -}}

{{/*
Mount HostPath in Volume Mount for all type of kubernetes objects
*/}}
{{- define "app-chart.hostPathVolumeMounts" -}}
{{- range $k, $v := .Values.spec.runtime.volumes.host_path }}
- name: {{ $k | quote }}
  mountPath: {{ $v.mount_path | quote }}
  {{- if $v.sub_path }}
  subPath: {{ $v.sub_path | quote }}
  {{- end }}
{{- end }}
{{- end -}}

{{/*
Mount Additional volumes in Volume Mount for all type of kubernetes objects
*/}}
{{- define "app-chart.additionalVolMounts" -}}
{{- if and ( hasKey .Values.advanced.common.app_chart.values  "additional_volume_mounts") (gt (len .Values.advanced.common.app_chart.values.additional_volume_mounts) 0) }}
{{- toYaml .Values.advanced.common.app_chart.values.additional_volume_mounts | nindent 0 }}
{{- end -}}
{{- end -}}

{{- define "app-chart.priorityClassName" -}}
{{- if eq .Release.Namespace "default" -}}
{{- include "app-chart.fullname" . -}}
{{- else -}}
{{- printf "%s-%s" .Release.Namespace (include "app-chart.fullname" .) -}}
{{- end -}}
{{- end -}}

{{/*
Add initContainers to the kubernetes deployments that will inherit from the module chart
*/}}
{{- define "app-chart.initContainers" -}}
{{- range $k, $v := .Values.advanced.common.app_chart.values.init_containers }}
- name: {{ $k }}
  image: {{ $v.image }}
  {{- if or (hasKey $v "env") (hasKey $v  "additional_k8s_env") }}
  env:
  {{- range $envName, $envValue := $v.env }}
  - name: {{ $envName | quote }}
    value: {{ $envValue | quote }}
  {{- end }}
  {{- if and ( hasKey $v  "additional_k8s_env") (gt (len $v.additional_k8s_env) 0) }}
  {{- toYaml $v.additional_k8s_env | nindent 2 }}
  {{- end }}
  {{- end }}
  {{- if and ( hasKey $v  "additional_k8s_env_from") (gt (len $v.additional_k8s_env_from) 0) }}
  envFrom:
  {{- toYaml $v.additional_k8s_env_from | nindent 2 }}
  {{- end }}
  imagePullPolicy: {{ $v.pull_policy | default "IfNotPresent" }}
{{- if and ( hasKey $v "runtime") (gt (len $v.runtime) 0) }}
{{- if  hasKey $v.runtime  "command" }}
{{- if gt (len $v.runtime.command) 0 }}
  command:
    {{- toYaml $v.runtime.command | nindent 2 }}
{{- end }}
{{- end }}
{{- if  hasKey $v.runtime  "args" }}
{{- if gt (len $v.runtime.args) 0 }}
  args:
    {{- toYaml $v.runtime.args | nindent 2 }}
{{- end }}
{{- end }}
{{- if and ( hasKey $v.runtime  "volumes") (gt (len $v.runtime.volumes) 0) }}
  volumeMounts:
{{- if and ( hasKey $v.runtime.volumes  "config_maps") (gt (len $v.runtime.volumes.config_maps) 0) }}
  {{- range $a, $b := $v.runtime.volumes.config_maps }}
  - name: {{ $a| quote }}
    mountPath: {{ $b.mount_path | quote }}
    {{- if $b.sub_path }}
    subPath: {{ $b.sub_path | quote }}
    {{- end }}
  {{- end }}
{{- end }}
{{- if and ( hasKey $v.runtime.volumes  "pvc") (gt (len $v.runtime.volumes.pvc) 0) }}
  {{- range $a, $b := $v.runtime.volumes.pvc }}
  - name: {{ $a| quote }}
    mountPath: {{ $b.mount_path | quote }}
    {{- if $b.sub_path }}
    subPath: {{ $b.sub_path | quote }}
    {{- end }}
  {{- end }}
{{- end }}
{{- if and ( hasKey $v.runtime.volumes  "host_path") (gt (len $v.runtime.volumes.host_path) 0) }}
  {{- range $a, $b := $v.runtime.volumes.host_path }}
  - name: {{ $a| quote }}
    mountPath: {{ $b.mount_path | quote }}
    {{- if $b.sub_path }}
    subPath: {{ $b.sub_path | quote }}
    {{- end }}
  {{- end }}
{{- end }}
{{- if and ( hasKey  $v.runtime.volumes  "secrets") (gt (len  $v.runtime.volumes.secrets) 0) }}
  {{- range $a, $b := $v.runtime.volumes.secrets }}
  - name: {{ $a| quote }}
    mountPath: {{ $b.mount_path | quote }}
    {{- if $b.sub_path }}
    subPath: {{ $b.sub_path | quote }}
    {{- end }}
  {{- end }}
{{- end }}
{{- if and ( hasKey  $v.runtime.volumes  "additional_volume_mounts") (gt (len  $v.runtime.volumes.additional_volume_mounts) 0) }}
{{- toYaml $v.runtime.volumes.additional_volume_mounts | nindent 2 }}
{{- end }}
{{- end }}
  resources:
  {{- if hasKey $v.runtime "size" }}
    limits:
    {{- if hasKey $v.runtime.size "cpu_limit" }}
      cpu: {{ $v.runtime.size.cpu_limit }}
    {{- else }}
      cpu: {{ $v.runtime.size.cpu }}
    {{- end }}
    {{- if hasKey $v.runtime.size "memory_limit" }}
      memory: {{ $v.runtime.size.memory_limit }}
    {{- else }}
      memory: {{ $v.runtime.size.memory }}
    {{- end }}
    requests:
      cpu: {{ $v.runtime.size.cpu }}
      memory: {{ $v.runtime.size.memory }}
    {{- end }}
  {{- end }}
{{- end }}
{{- end }}


{{/*
Mount volumes of sidecars in volumes for all type of kubernetes objects
*/}}
{{- define "app-chart.sidecarVolume" -}}
{{- range $k, $v := .Values.advanced.common.app_chart.values.sidecars }}
{{- if and ( hasKey $v "runtime") (gt (len $v.runtime) 0) }}
{{- if and ( hasKey $v.runtime  "volumes") (gt (len $v.runtime.volumes) 0) }}
{{- if and ( hasKey $v.runtime.volumes  "config_maps") (gt (len $v.runtime.volumes.config_maps) 0) }}
{{- range $a, $b := $v.runtime.volumes.config_maps }}
- name: {{ $a | quote }}
  configMap:
    name: {{ $b.name | quote }}
{{- end }}
{{- end }}
{{- if and ( hasKey $v.runtime.volumes  "secrets") (gt (len $v.runtime.volumes.secrets) 0) }}
{{- range $a, $b := $v.runtime.volumes.secrets }}
- name: {{ $a | quote }}
  secret:
    secretName: {{ $b.name | quote }}
{{- end }}
{{- end }}
{{- if and ( hasKey $v.runtime.volumes  "pvc") (gt (len $v.runtime.volumes.pvc) 0) }}
{{- range $a, $b := $v.runtime.volumes.pvc }}
- name: {{ $a | quote }}
  persistentVolumeClaim:
    claimName: {{ $b.claim_name | quote }}
{{- end }}
{{- end -}}
{{- if and ( hasKey $v.runtime.volumes  "host_path") (gt (len $v.runtime.volumes.host_path) 0) }}
{{- range $a, $b := $v.runtime.volumes.host_path }}
- name: {{ $a | quote }}
  hostPath:
    path: {{ ($b.host_path | default $b.mount_path) | quote }}
    {{- if and ( hasKey $b "type") (gt (len $b.type) 0) }}
    type: {{ $b.type | quote }}
    {{- end }}
{{- end }}
{{- end -}}
{{- if and ( hasKey $v.runtime.volumes  "additional_volumes") (gt (len $v.runtime.volumes.additional_volumes) 0) }}
{{ toYaml $v.runtime.volumes.additional_volumes }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Mount volumes of initcontainer in volumes for all type of kubernetes objects
*/}}
{{- define "app-chart.initcontainerVolume" -}}
{{- range $k, $v := .Values.advanced.common.app_chart.values.init_containers }}
{{- if and ( hasKey $v "runtime") (gt (len $v.runtime) 0) }}
{{- if and ( hasKey $v.runtime  "volumes") (gt (len $v.runtime.volumes) 0) }}
{{- if and ( hasKey $v.runtime.volumes  "config_maps") (gt (len $v.runtime.volumes.config_maps) 0) }}
{{- range $a, $b := $v.runtime.volumes.config_maps }}
- name: {{ $a | quote }}
  configMap:
    name: {{ $b.name | quote }}
{{- end }}
{{- end }}
{{- if and ( hasKey $v.runtime.volumes  "secrets") (gt (len $v.runtime.volumes.secrets) 0) }}
{{- range $a, $b := $v.runtime.volumes.secrets }}
- name: {{ $a | quote }}
  secret:
    secretName: {{ $b.name | quote }}
{{- end }}
{{- end }}
{{- if and ( hasKey $v.runtime.volumes  "pvc") (gt (len $v.runtime.volumes.pvc) 0) }}
{{- range $a, $b := $v.runtime.volumes.pvc }}
- name: {{ $a | quote }}
  persistentVolumeClaim:
    claimName: {{ $b.claim_name | quote }}
{{- end }}
{{- end -}}
{{- if and ( hasKey $v.runtime.volumes  "host_path") (gt (len $v.runtime.volumes.host_path) 0) }}
{{- range $a, $b := $v.runtime.volumes.host_path }}
- name: {{ $a | quote }}
  hostPath:
    path: {{ ($b.host_path | default $b.mount_path) | quote }}
    {{- if and ( hasKey $b "type") (gt (len $b.type) 0) }}
    type: {{ $b.type | quote }}
    {{- end }}
{{- end }}
{{- end -}}
{{- if and ( hasKey $v.runtime.volumes  "additional_volumes") (gt (len $v.runtime.volumes.additional_volumes) 0) }}
{{ toYaml $v.runtime.volumes.additional_volumes }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Runtime Class Name for GKE Sandboxed pod
*/}}
{{- define "app-chart.runtime_class_name" -}}
{{- $runtimeClassNameValue := .Values.spec.runtime_class_name }}
{{- if $runtimeClassNameValue }}
runtimeClassName: {{ $runtimeClassNameValue }}
{{- end }}
{{- end -}}


{{/*
Lifecycle support for deployment, Job & cronJob.
*/}}
{{- define "app-chart.lifecycle" -}}
{{- if or (hasKey .Values.spec.runtime "lifecycle") (hasKey .Values.advanced.common.app_chart.values "lifecycle") }}
lifecycle:
  {{- if hasKey .Values.spec.runtime "lifecycle" }}
  {{- toYaml .Values.spec.runtime.lifecycle | nindent 2 }}
  {{- else if hasKey .Values.advanced.common.app_chart.values "lifecycle" }}
  {{- toYaml .Values.advanced.common.app_chart.values.lifecycle | nindent 2 }}
  {{- end }}
{{- end }}
{{- end }}

{{/*
Get the replicas from autoscaling or instance_count and default to 1 if not set
*/}}
{{- define "app-chart.replicas" -}}
{{- if and (hasKey .Values.spec.runtime "autoscaling") (hasKey .Values.spec.runtime.autoscaling "min") }}
{{- default 1 .Values.spec.runtime.autoscaling.min }}
{{- else  }}
{{- default 1 .Values.spec.runtime.instance_count }}
{{- end }}
{{- end }}
