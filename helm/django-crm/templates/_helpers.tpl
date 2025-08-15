{{/*
Expand the name of the chart.
*/}}
{{- define "django-crm.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "django-crm.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "django-crm.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "django-crm.labels" -}}
helm.sh/chart: {{ include "django-crm.chart" . }}
{{ include "django-crm.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "django-crm.selectorLabels" -}}
app.kubernetes.io/name: {{ include "django-crm.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "django-crm.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "django-crm.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
CRM image repository
*/}}
{{- define "django-crm.crm.image" -}}
{{- $registry := .Values.global.registry -}}
{{- $repository := .Values.crm.image.repository -}}
{{- $tag := .Values.crm.image.tag | default .Values.global.tag -}}
{{- printf "%s/%s:%s" $registry $repository $tag }}
{{- end }}

{{/*
MySQL image
*/}}
{{- define "django-crm.mysql.image" -}}
{{- printf "%s:%s" .Values.mysql.image.repository .Values.mysql.image.tag }}
{{- end }}

{{/*
Adminer image
*/}}
{{- define "django-crm.adminer.image" -}}
{{- printf "%s:%s" .Values.adminer.image.repository .Values.adminer.image.tag }}
{{- end }}
