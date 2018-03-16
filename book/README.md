# Preface

How do I scale and grow my infrastructure for my business?

More importantly, how do I prevent a crisis? How do I know what my decisions will also impact? Am I asking the right questions? 

This book will help answer questions, but also help with the background information needed when making decisions that impact your business's infrastructure.

Despite the complicated realities of modern computers, it is possible to build an infrastructure that delivers on the promises of cloud computing. By the end of this book, you'll understand how.

## Who Is This Book For?

This book is intended for anyone thinking about or facing issues with scaling and growing their infrastructure, and anyone who wants to understand how to build infrastructure for production use.

The main skill set you'll need to follow along is some familiarity with [the Linux command line](https://www.digitalocean.com/community/tutorial_series/getting-started-with-linux), but each chapter includes code examples, and many of the key takeaways will be framed at a high level and easy to apply conceptually as well.

The accompanying repository <!-- TODO: link --> deploys this book's sample infrastructure to give you a hands-on starting point as you follow along, but the corresponding chapters have comprehensive technical explanations so you'll understand what you're doing and why each step of the way.

## What Will You Learn From This Book?

This book will give you both the conceptual understanding and the hands-on practical skills to build a successful infrastructure on DigitalOcean. We based our recommendations on the real world problems that our customers encountered and that we helped them solve.

(Want to know more about DigitalOcean and the authors of this book? That's in the next chapter. This chapter is about you.)

Our goal is for you to be able to make sure your infrastructure stays online reliably and scales out easily, your data is secure, and any problems are easy to troubleshoot.

We outline infrastructure best practices and, just as importantly, we explain _why_ those practices prevent pain points and issues. Understanding the "why" will empower you to make the right decisions for your use case.

Then, because you'll understand how everything works, you'll have the knowledge to adapt our example infrastructure for your own needs or build your own from scratch.

## How Should You Use This Book?

This book is broken into five parts with a few chapters each, plus this introduction and a conclusion. You can see the structure in the table of contents on the previous page, too. <!-- TODO: make sure we generate a TOC -->

Parts 2 through 5 are the meat of the book. That's where we'll teach you how to prevent downtime, scale your infrastructure, keep your data safe, make it easy to troubleshoot issues, identify performance bottlenecks, and stay protected from security threats.

Before we do that, we want to make sure that everyone start with the same foundation. That's what Part 1, Background and Setup, is for. It consists of the first three chapters of the book. Chapter 1 gives some background on DigitalOcean and us, the authors. Chapter 2 covers the problems we see businesses encounter with cloud computing and our solutions to them (i.e. a more detailed overview of Parts 2 through 5). Chapter 3 walks you through the tools we'll use to build the infrastructure described in this book, and how to get your environment set up to follow along.

## Follow Code Examples

This book was created as an open source project. Like many open source projects, the files and data that are used to generate the book are available in a repository. The repository is available online at https://github.com/{{ book.nav-repo }}. The two important directories are "book" which includes the markdown files for this book, and "example-code" which include all the code examples found in the book. 

#### Book Contents:
We are using the Gitbook Toolchain[^1] to create this book. You'll find the contents formatted in markdown. 
#### Code Examples: 
This book may mention a YAML file to be used as user-data when creating a Droplet or deploying a configuration with an Ansible playbook. All of those examples are found organized by chapter in the "code" directory. 
<!-- TODO: Add OSS license to repo -->

## Let's Get Started!

We wrote this book with a single narrative in mind, which means it flows naturally if you read it linearly from start to finish. However, we kept each section as modular as possible, so if you're already familiar with the concepts covered in a particular chapter, you can skim it or just skip to the next one.

[^1]: Gitbook Toolchain: https://toolchain.gitbook.com/ 

