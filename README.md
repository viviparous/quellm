# QUELLM (Quel LLM)
An easy-to-use Perl client for use with [Ollama server](https://ollama.com).

quellm is a client for querying an Ollama server in your local network. I coded quellm so I could use _offline_ LLMs for querying. 

I wanted an Ollama client that is easy to use. See the Usage section below for a summary of how to use quellm to query 1 LLM, a selection of LLMs, or *all* the installed LLMs. 

You can also pull (install) a model, delete a model, and list the models available from <ollama.com>. 

Ollama is easy to install. For information about installing Ollama, visit <[ollama.com](https://ollama.com)>.

Once you have an ollama server configured to receive REST queries, run "perl quellm.pl" without arguments. 
quellm will ask you to identify the IP address and port of your ollama REST server. 

<img width="666" height="120" alt="image" src="https://github.com/user-attachments/assets/35340a0a-4cc3-4d0f-99c5-210521858dd7" />

A local configuration file will be created and quellm will use it for future queries.

## USAGE
The help text for quellm shows the optional arguments.
<code>
Usage:
quellm.pl <no arguments> (lists current local models)
quellm.pl library (lists models available at ollama.com, requires Internet connexion)
quellm.pl pull "modelname" (requires Internet connexion; obtain list of models using "library")
quellm.pl modelint "question"
quellm.pl int1,int2,int3 "question"
quellm.pl all "question"
quellm.pl delete "modelname" (deletes model from local server)
</code>
  
## Suggested LLMs for Coding and General Querying

<img width="570" height="307" alt="image" src="https://github.com/user-attachments/assets/050e3a83-f29a-4f8f-985f-16e5588e8218" />

For coding, I have found the following LLMs useful:
wizardcoder, codestral, codegemma, deepseek-coder-v2, codellama, mistral-nemo, llama3

mistral-nemo and llama3 are also useful for general queries. I have used translategemma for (human) language questions.  

quellm presents the "library" list of LLM names in columns, with "cloud" LLMs coloured blue.

<img width="937" height="691" alt="image" src="https://github.com/user-attachments/assets/ca757d87-d2c1-4b67-aba5-ed40c778f53e" />

## Perl modules used
The following non-core modules are used in quellm:

* LWP::UserAgent 
* Config::Tiny 
* Tie::IxHash 
* Try::Tiny 

## Comments and information about using LLMs for coding
I have found the LLMs mentioned above useful for coding assistance. In fact, I queried the above LLMs a few times while developing quellm. 

The LLMs often provide conflicting responses. You will find that some LLMs perform better than others. Some are quick to respond, some are very slow. You will want to experiment. 

If it helps, here are the specifications of my LLM server:
* AMD 5600X CPU, 32 GB RAM
* AMD 9060 XT GPU, 16 GB VRAM
* OS MW10 (I had to fiddle with the GPU driver. I have read that Ollama is easier to configure for Linux.)    

## Example of a query sent to a subset of the installed LLMs
<img width="867" height="622" alt="image" src="https://github.com/user-attachments/assets/a1b479d9-a1d5-4bc7-b33c-2bdaebb26f70" />

