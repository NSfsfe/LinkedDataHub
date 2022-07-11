#!/usr/bin/env bash

# SPDX-FileCopyrightText: 2017 Martynas Jusevicius <martynas@atomgraph.com> 
# SPDX-FileCopyrightText: 2017 LinkedDataHub
#
# SPDX-License-Identifier: Apache-2.0

# LinkedDataHub


set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_backend_cache "$END_USER_VARNISH_SERVICE"
purge_backend_cache "$ADMIN_VARNISH_SERVICE"

pushd . > /dev/null && cd "$SCRIPT_ROOT/admin/model"

# create class

namespace_doc="${END_USER_BASE_URL}ns"
namespace="${namespace_doc}#"
ontology_doc="${ADMIN_BASE_URL}model/ontologies/namespace/"
class="${namespace_doc}#NewClass"

./create-class.sh \
  -f "$OWNER_CERT_FILE" \
  -p "$OWNER_CERT_PWD" \
  -b "$ADMIN_BASE_URL" \
  --uri "$class" \
  --label "New class" \
  --slug new-class \
  --sub-class-of "https://www.w3.org/ns/ldt/document-hierarchy#Item" \
  "$ontology_doc"

popd > /dev/null

# clear ontology from memory

pushd . > /dev/null && cd "$SCRIPT_ROOT/admin"

./clear-ontology.sh \
  -f "$OWNER_CERT_FILE" \
  -p "$OWNER_CERT_PWD" \
  -b "$ADMIN_BASE_URL" \
  --ontology "$namespace"

popd > /dev/null

# check that the class is present in the ontology

curl -k -f -s -N \
  -H "Accept: application/n-triples" \
  "$namespace_doc" \
| grep "$class" > /dev/null

# TO-DO: test constructor of the created class?
