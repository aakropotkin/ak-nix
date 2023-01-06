{ nixpkgs  ? builtins.getFlake "nixpkgs"
, system   ? builtins.currentSystem
, pkgs     ? import nixpkgs.legacyPackages.${system}
, pandoc   ? pkgs.pandoc
}:
let

  pandocInputFormats = [
    "biblatex" "bibtex" "commonmark" "commonmark_x" "creole" "csljson" "csv"
    "docbook" "docx" "dokuwiki" "epub" "fb2" "gfm" "haddock" "html" "ipynb"
    "jats" "jira" "json" "latex" "man" "markdown" "markdown_github"
    "markdown_mmd" "markdown_phpextra" "markdown_strict" "mediawiki" "muse"
    "native" "odt" "opml" "org" "rst" "rtf" "t2t" "textile" "tikiwiki" "twiki"
    "vimwiki"
  ];

  pandocOutputFormats = [
    "asciidoc" "asciidoctor" "beamer" "biblatex" "bibtex" "commonmark"
    "commonmark_x" "context" "csljson" "docbook" "docbook4" "docbook5" "docx"
    "dokuwiki" "dzslides" "epub" "epub2" "epub3" "fb2" "gfm" "haddock" "html"
    "html4" "html5" "icml" "ipynb" "jats" "jats_archiving"
    "jats_articleauthoring" "jats_publishing" "jira" "json" "latex" "man"
    "markdown" "markdown_github" "markdown_mmd" "markdown_phpextra"
    "markdown_strict" "markua" "mediawiki" "ms" "muse" "native" "odt"
    "opendocument" "opml" "org" "pdf" "plain" "pptx" "revealjs" "rst" "rtf" "s5"
    "slideous" "slidy" "tei" "texinfo" "textile" "xwiki" "zimwiki"
  ];

  pandocOutputExts = {
    commonmark        = "md";
    markdown          = "md";
    markdown_github   = "md";
    markdown_strict   = "md";
    markdown_phpextra = "md";
    markdown_mmd      = "mmd";
    docbook           = "xml";
    docbook4          = "xml";
    docbook5          = "xml";
    opendocument      = "odt";
    texinfo           = "texi";
  };


/* -------------------------------------------------------------------------- */

  runPandoc = { from, to, toExt ? pandocOutputExts.${to} or to }:
    file:
    let
      iname = file.name or file.drvAttrs.name or "document";
      # Darwin's broken greedy matching is such bullshit...
      m = builtins.match "(.*)-docbook\\.[^.]*" iname;
      m' = builtins.match "(.*)\\.[^.]*" iname;
      bname = if ( m != null )  then ( builtins.head m  ) else
              if ( m' != null ) then ( builtins.head m' ) else iname;
    in derivation {
      name = bname + "." + toExt;
      inherit system;
      builder = "${pandoc}/bin/pandoc";
      args = [
        "-o" ( builtins.placeholder "out" )
        "-f" from
        "-t" to
        file
      ];
    };

  docbookToHtml = runPandoc { from = "docbook"; to = "html5"; };
  docbookToPdf  = runPandoc { from = "docbook"; to = "pdf"; };
  docbookToJira = runPandoc { from = "docbook"; to = "jira"; };
  docbookToTexi = runPandoc { from = "docbook"; to = "texinfo"; };
  docbookToOrg  = runPandoc { from = "docbook"; to = "org"; };
  docbookToMan  = runPandoc { from  = "docbook"; to = "man"; };
  docbookToManN = n: runPandoc {
    from  = "docbook";
    to    = "man";
    toExt = toString n;
  };


/* -------------------------------------------------------------------------- */

in {
  inherit runPandoc;
  inherit docbookToHtml docbookToPdf docbookToJira docbookToTexi docbookToOrg;
  inherit docbookToMan docbookToManN;
  meta.pandoc = {
    inputFormats = pandocInputFormats;
    outputFormats = pandocOutputFormats;
    defaultOutputExtensions = pandocOutputExts;
  };
}
