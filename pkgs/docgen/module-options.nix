{ nixpkgs            ? builtins.getFlake "nixpkgs"
, system             ? builtins.currentSystem
, pkgsFor            ? nixpkgs.legacyPackages.${system}
, lib                ? nixpkgs.lib
, genDoc             ? import "${nixpkgs}/nixos/lib/make-options-doc"
, pandocGen          ? import ./pandoc { inherit (pkgsFor) pandoc; }
, infoGen            ? import ./makeinfo { inherit (pkgsFor) texinfo; }
, linkFarmFromDrvs   ? pkgsFor.linkFarmFromDrvs
}:
let
  inherit (pandocGen) docbookToManN docbookToTexi docbookToHtml docbookToOrg;

  docbookToMan5 = docbookToManN 5;

  generateDocsForOptions = options:
    let
      docs' = genDoc { inherit lib options; pkgs = pkgsFor; };
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
