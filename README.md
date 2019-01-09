# paedML-ssl

SSL Proxy for paedML

# Usage

First build the image

For this you need a server with vagrant and virtualbox already installed and setup

Then run `bash build.sh`

This should create a `dist` folder containing the `credentials` file and the VM itself, named `paedML-ssl.ova`

# Why?

Installing it on the paedML SUSE SLE 12 Server is basically a mess

Setting up a VM that requires only minor tweaking to work is preferred by those that need to deal with this later on

So that's what I've been creating during my internship
