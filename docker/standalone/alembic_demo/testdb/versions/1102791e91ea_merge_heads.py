"""Merge heads

Revision ID: 1102791e91ea
Revises: 6852ef9e5362, a83d1355eff5
Create Date: 2024-07-24 13:53:53.308155

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '1102791e91ea'
down_revision: Union[str, None] = ('6852ef9e5362', 'a83d1355eff5')
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    pass


def downgrade() -> None:
    pass
