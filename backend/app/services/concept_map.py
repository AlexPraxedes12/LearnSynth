from typing import Dict, List
import spacy

nlp = spacy.load("en_core_web_sm")


def generate_concept_map(text: str) -> Dict:
    doc = nlp(text)
    nodes = set()
    links: List[Dict] = []
    for sent in doc.sents:
        subject = None
        obj = None
        verb = None
        for token in sent:
            if token.dep_ in ("nsubj", "nsubjpass"):
                subject = token.text
            elif token.dep_ in ("dobj", "pobj"):
                obj = token.text
            elif token.dep_ == "ROOT":
                verb = token.lemma_
        if subject and obj:
            nodes.add(subject)
            nodes.add(obj)
            links.append({"source": subject, "target": obj, "label": verb or ""})
    return {"nodes": [{"id": n} for n in nodes], "links": links}


def concept_map_image(concept_map: Dict) -> bytes:
    import graphviz

    dot = graphviz.Digraph()
    for n in concept_map["nodes"]:
        dot.node(n["id"])
    for l in concept_map["links"]:
        dot.edge(l["source"], l["target"], label=l.get("label", ""))
    return dot.pipe(format="png")
