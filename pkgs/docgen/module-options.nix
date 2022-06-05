{ nixpkgs            ? builtins.getFlake "nixpkgs"
, system             ? builtins.currentSystem
, pkgs               ? nixpkgs.legacyPackages.${system}
, lib                ? nixpkgs.lib
, genDoc             ? import "${nixpkgs}/nixos/lib/make-options-doc"
, pandocGen          ? import ../pandoc { inherit (pkgs) pandoc; }
, infoGen            ? import ../makeinfo { inherit (pkgs) texinfo; }
, linkFarmFromDrvs   ? pkgs.linkFarmFromDrvs
}:
let
  inherit (pandocGen) docbookToManN docbookToTexi docbookToHtml docbookToOrg;

  docbookToMan5 = docbookToManN 5;

  generateDocsForOptions = options:
    let
      docs' = genDoc { inherit pkgs lib options; };
      texi = docbookToTexi docs'.optionsDocBook;
      singles = {
        asciidoc = docs'.optionsAsciiDoc // { name = "options.asciidoc"; };
        markdown = docs'.optionsCommonMark // { name = "options.md"; };
        docbook  = docs'.optionsDocBook // { name = "options-docbook.xml"; };
        json     = docs'.optionsJSON // { name = "options.json"; };
        xml      = docs'.optionsXML // { name = "options.xml"; };
        html     = docbookToHtml docs'.optionsDocBook;
        man      = docbookToMan5 docs'.optionsDocBook;
        org      = docbookToOrg docs'.optionsDocBook;
        info     = infoGen.texiToInfo texi;
        inherit texi;
      };
    in singles // {
      all = linkFarmFromDrvs "docs-full"
        ( builtins.attrValues ( builtins.removeAttrs docs' ["optionsNix"] ) );
    };

in {
  inherit generateDocsForOptions;
}
