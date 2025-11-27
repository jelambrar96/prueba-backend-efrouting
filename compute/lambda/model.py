from typing import List, Optional
from pydantic import BaseModel


# -------------------------------
# Models for nested structures
# -------------------------------

class Patch(BaseModel):
    small: Optional[str]
    large: Optional[str]


class Reddit(BaseModel):
    campaign: Optional[str]
    launch: Optional[str]
    media: Optional[str]
    recovery: Optional[str]


class Flickr(BaseModel):
    small: List[str]
    original: List[str]


class Links(BaseModel):
    patch: Patch
    reddit: Reddit
    flickr: Flickr
    presskit: Optional[str]
    webcast: Optional[str]
    youtube_id: Optional[str]
    article: Optional[str]
    wikipedia: Optional[str]


class Fairings(BaseModel):
    reused: Optional[bool]
    recovery_attempt: Optional[bool]
    recovered: Optional[bool]
    ships: List[str]


class Core(BaseModel):
    core: Optional[str]
    flight: Optional[int]
    gridfins: Optional[bool]
    legs: Optional[bool]
    reused: Optional[bool]
    landing_attempt: Optional[bool]
    landing_success: Optional[bool]
    landing_type: Optional[str]
    landpad: Optional[str]


class Launch(BaseModel):
    fairings: Optional[Fairings]
    links: Links
    static_fire_date_utc: Optional[str]
    static_fire_date_unix: Optional[int]
    net: bool
    window: Optional[int]
    rocket: str
    success: Optional[bool]
    failures: List[dict]
    details: Optional[str]
    crew: List[str]
    ships: List[str]
    capsules: List[str]
    payloads: List[str]
    launchpad: str
    flight_number: int
    name: str
    date_utc: str
    date_unix: int
    date_local: str
    date_precision: str
    upcoming: bool
    cores: List[Core]
    auto_update: bool
    tbd: bool
    launch_library_id: Optional[str]
    id: str


# -------------------------------
# Model for the top-level response
# -------------------------------

class SpaceXResponse(BaseModel):
    docs: List[Launch]
    totalDocs: int
    offset: int
    limit: int
    totalPages: int
    page: int
    pagingCounter: int
    hasPrevPage: bool
    hasNextPage: bool
    prevPage: Optional[int]
    nextPage: Optional[int]
