resource "oci_core_instance" "gatling" {
    compartment_id      = "${var.compartment_ocid}"
    availability_domain = "${var.core_instance_availability_domain}"
    display_name        = "${var.core_instance_name}"
    shape               = "${var.core_instance_shape}"

    create_vnic_details {
        subnet_id = "${var.core_instance_subnet_ocid}"
    }

    source_details {
        source_type = "image"
        source_id   = "${var.instance_image_ocid[var.region]}"
    }

    metadata = {
        ssh_authorized_keys = "${file(var.core_instance_ssh_public_key_file)}"
    }

    connection {
        type        = "ssh"
        host        = "${self.public_ip}"
        user        = "opc"
        private_key = "${file(var.core_instance_ssh_private_key_file)}"
    }

    provisioner "remote-exec" "install jdk & gatling" {
        inline = [
            #"sudo yum -y update",
            "sudo yum -y install java-1.8.0-openjdk",
            "wget https://repo1.maven.org/maven2/io/gatling/highcharts/gatling-charts-highcharts-bundle/3.0.1.1/gatling-charts-highcharts-bundle-3.0.1.1-bundle.zip -O /tmp/gatling-charts-highcharts-bundle-3.0.1.1-bundle.zip",
            "mkdir ~/gatling",
            "unzip /tmp/gatling-charts-highcharts-bundle-3.0.1.1-bundle.zip -d ~/gatling",
        ]
    }

    provisioner "remote-exec" "preparation for copying files" {
        inline = [
            "mkdir ~/gatling/gatling-charts-highcharts-bundle-3.0.1.1/user-files/simulations/atpstore",
        ]
    }

    provisioner "file" {
        source = "./gatling-home/simulations/atpstore/atpstoreRead.scala"
        destination = "/home/opc/gatling/gatling-charts-highcharts-bundle-3.0.1.1/user-files/simulations/atpstore/atpstoreRead.scala"
    }

    provisioner "file" {
        source = "./gatling-home/run.sh"
        destination = "/home/opc/gatling/gatling-charts-highcharts-bundle-3.0.1.1/run.sh"
    }

    provisioner "file" {
        source = "./gatling-home/endpoints.txt"
        destination = "/home/opc/gatling/gatling-charts-highcharts-bundle-3.0.1.1/endpoints.txt"
    }

    provisioner "remote-exec" "change file permission" {
        inline = [
            "chmod +x /home/opc/gatling/gatling-charts-highcharts-bundle-3.0.1.1/run.sh",
        ]
    }

}