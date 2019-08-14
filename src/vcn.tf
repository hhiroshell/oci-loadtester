/*
 * Copyright (c) 2019 Hiroshi Hayakawa <hhiroshell@gmail.com>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND
 */

locals {
    cidr-public-internet = "0.0.0.0/0"
    cidr-loadtester-vcn = "10.0.0.0/16"
    cidr-loadtester-sn-ad1 = "10.0.10.0/24"
}

resource "oci_core_virtual_network" "loadtester-vcn" {
    display_name   = "loadtester-vcn"
    compartment_id = "${var.compartment_ocid}"
    cidr_block     = "${local.cidr-loadtester-vcn}"
    dns_label      = "loadtester"
    provisioner "local-exec" {
        command = "sleep 5"
    }
}

resource "oci_core_internet_gateway" "loadtester-ig" {
    display_name   = "loadtester-ig"
    compartment_id = "${var.compartment_ocid}"
    vcn_id         = "${oci_core_virtual_network.loadtester-vcn.id}"
}

resource "oci_core_default_route_table" "loadtester-df-rt" {
    display_name   = "loadtester-df-rt"
    manage_default_resource_id = "${oci_core_virtual_network.loadtester-vcn.default_route_table_id}"
    route_rules {
        destination = "${local.cidr-public-internet}"
        network_entity_id = "${oci_core_internet_gateway.loadtester-ig.id}"
    }
}

resource "oci_core_security_list" "loadtester-sl" {
    display_name   = "loadtester-sl"
    compartment_id = "${var.compartment_ocid}"
    vcn_id         = "${oci_core_virtual_network.loadtester-vcn.id}"
    egress_security_rules = [
        {
            protocol    = "all"
            destination = "${local.cidr-public-internet}"
        }
    ]
    ingress_security_rules = [
        {
            protocol = "6"
            source   = "${local.cidr-public-internet}"
            tcp_options {
                "max" = 22
                "min" = 22
            }
        }
    ]
}

resource "oci_core_subnet" "loadtester-sn-ad1" {
    display_name        = "loadtester-sn-ad1"
    compartment_id      = "${var.compartment_ocid}"
    vcn_id              = "${oci_core_virtual_network.loadtester-vcn.id}"
    availability_domain = "${lookup(data.oci_identity_availability_domains.ads.availability_domains[0], "name")}"
    cidr_block          = "${local.cidr-loadtester-sn-ad1}"
    security_list_ids   = ["${oci_core_security_list.loadtester-sl.id}"]
    provisioner "local-exec" {
        command = "sleep 5"
    }
}